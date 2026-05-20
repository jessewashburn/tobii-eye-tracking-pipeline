#!/usr/bin/env python3
"""
Eye Tracking Data Processor
Author: Jesse Washburn
Created: 4/13/24
Updated: 9/22/25

A comprehensive script that combines eye tracking data from multiple participants
and creates abbreviated AOI (Area of Interest) mappings for analysis.

This script performs two main functions:
1. Combines all Final_Processed_Data files for participants P2-P49 into a single Excel file
2. Creates abbreviated AOI names and generates a legend for easier analysis

"""

import argparse
import pandas as pd
import numpy as np
from pathlib import Path
import string
from typing import Dict, List


class EyeTrackingDataProcessor:
    """
    A class to process and combine eye tracking data from multiple participants.
    """
    
    def __init__(self, data_directory: str, participant_range: tuple = (2, 50)):
        """
        Initialize the processor with configuration parameters.
        
        Args:
            data_directory (str): Path to directory containing input files
            participant_range (tuple): Range of participant numbers (start, end)
        """
        # Configuration variables
        self.data_directory = Path(data_directory)
        self.participant_start, self.participant_end = participant_range
        
        # Column mappings
        self.input_columns = ['Chart Name', 'Name of AOI Hit']
        self.column_mapping = {
            'Chart Name': 'Chart Type',
            'Name of AOI Hit': 'AOI'
        }
        
        # Output file names
        self.combined_data_filename = 'Combined_Data.xlsx'
        self.abbreviated_data_filename = 'Abbreviated_Combined_Data.xlsx'
        self.legend_filename = 'AOI_Abbreviation_Legend.xlsx'
        
        # Abbreviation characters (uppercase, lowercase, digits)
        self.abbreviation_chars = (
            list(string.ascii_uppercase) + 
            list(string.ascii_lowercase) + 
            list(string.digits)
        )
    
    def generate_file_list(self) -> List[str]:
        """
        Generate list of input file names to process.
        
        Returns:
            List[str]: List of file names to process
        """
        # Generate standard participant files
        file_names = [
            f"P{index}_Processed_Data.xlsx" 
            for index in range(self.participant_start, self.participant_end)
        ]
        return file_names
    
    def extract_participant_id(self, file_name: str) -> str:
        """
        Extract participant ID from file name.
        
        Args:
            file_name (str): Name of the file
            
        Returns:
            str: Participant ID
        """
        # Standard file format: extract participant ID before first underscore
        return file_name.split('_')[0]
    
    def process_single_file(self, file_path: Path) -> pd.DataFrame:
        """
        Process a single Excel file and return formatted DataFrame.
        
        Args:
            file_path (Path): Path to the Excel file
            
        Returns:
            pd.DataFrame: Processed data from the file
        """
        try:
            # Load data from Excel file
            data = pd.read_excel(file_path)
            
            # Extract and rename required columns
            data = data[self.input_columns].copy()
            data.rename(columns=self.column_mapping, inplace=True)
            
            # Add participant ID
            participant_id = self.extract_participant_id(file_path.name)
            data['Part ID'] = participant_id
            
            # Forward fill missing values in Chart Type column
            data['Chart Type'] = data['Chart Type'].ffill()
            
            return data
            
        except Exception as e:
            print(f"Error processing file {file_path.name}: {str(e)}")
            return pd.DataFrame()
    
    def combine_participant_data(self) -> pd.DataFrame:
        """
        Combine data from all participant files into a single DataFrame.
        
        Returns:
            pd.DataFrame: Combined data from all participants
        """
        print("Starting data combination process...")
        
        # Initialize empty DataFrame for combined data
        combined_data = pd.DataFrame()
        file_names = self.generate_file_list()
        
        # Process each file
        processed_files = 0
        for file_name in file_names:
            file_path = self.data_directory / file_name
            
            if file_path.exists():
                print(f"Processing: {file_name}")
                file_data = self.process_single_file(file_path)
                
                if not file_data.empty:
                    combined_data = pd.concat([combined_data, file_data], ignore_index=True)
                    processed_files += 1
            else:
                print(f"Warning: File not found - {file_name}")
        
        print(f"Successfully processed {processed_files} files")
        return combined_data
    
    def create_abbreviation_legend(self, unique_aois: List[str]) -> Dict[str, str]:
        """
        Create a mapping of AOI names to single-character abbreviations.
        
        Args:
            unique_aois (List[str]): List of unique AOI names
            
        Returns:
            Dict[str, str]: Mapping of AOI names to abbreviations
        """
        if len(unique_aois) > len(self.abbreviation_chars):
            print(f"Warning: More AOIs ({len(unique_aois)}) than available abbreviations ({len(self.abbreviation_chars)})")
        
        return {
            aoi: abbr 
            for aoi, abbr in zip(unique_aois, self.abbreviation_chars)
        }
    
    def save_combined_data(self, data: pd.DataFrame) -> Path:
        """
        Save combined data to Excel file.
        
        Args:
            data (pd.DataFrame): Combined data to save
            
        Returns:
            Path: Path where the file was saved
        """
        output_path = self.data_directory / self.combined_data_filename
        
        # Ensure output directory exists
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Save to Excel
        data.to_excel(output_path, index=False)
        print(f"Combined data saved to: {output_path}")
        
        return output_path
    
    def create_abbreviated_data(self, data: pd.DataFrame) -> tuple:
        """
        Create abbreviated AOI data and legend.
        
        Args:
            data (pd.DataFrame): Combined data with full AOI names
            
        Returns:
            tuple: (abbreviated_data, legend_dict)
        """
        print("Creating AOI abbreviations...")
        
        # Get unique AOI names
        unique_aois = data['AOI'].unique()
        print(f"Found {len(unique_aois)} unique AOIs")
        
        # Create abbreviation legend
        legend = self.create_abbreviation_legend(unique_aois)
        
        # Apply abbreviations to data
        data_copy = data.copy()
        data_copy['Abbreviated AOI'] = data_copy['AOI'].map(legend)
        
        return data_copy, legend
    
    def save_abbreviated_data_and_legend(self, abbreviated_data: pd.DataFrame, legend: Dict[str, str]):
        """
        Save abbreviated data and legend to separate Excel files.
        
        Args:
            abbreviated_data (pd.DataFrame): Data with abbreviated AOIs
            legend (Dict[str, str]): AOI abbreviation legend
        """
        # Save abbreviated data
        abbreviated_path = self.data_directory / self.abbreviated_data_filename
        abbreviated_data.to_excel(abbreviated_path, index=False)
        print(f"Abbreviated data saved to: {abbreviated_path}")
        
        # Save legend
        legend_path = self.data_directory / self.legend_filename
        legend_df = pd.DataFrame(list(legend.items()), columns=['AOI', 'Abbreviation'])
        legend_df.to_excel(legend_path, index=False)
        print(f"AOI abbreviation legend saved to: {legend_path}")
    
    def process_all_data(self):
        """
        Execute the complete data processing pipeline.
        """
        print("=" * 60)
        print("Eye Tracking Data Processing Pipeline")
        print("=" * 60)
        
        # Step 1: Combine all participant data
        combined_data = self.combine_participant_data()
        
        if combined_data.empty:
            print("Error: No data was successfully processed. Exiting.")
            return
        
        print(f"Total combined records: {len(combined_data)}")
        
        # Step 2: Save combined data
        self.save_combined_data(combined_data)
        
        # Step 3: Create abbreviated data and legend
        abbreviated_data, legend = self.create_abbreviated_data(combined_data)
        
        # Step 4: Save abbreviated data and legend
        self.save_abbreviated_data_and_legend(abbreviated_data, legend)
        
        print("=" * 60)
        print("Processing completed successfully!")
        print("=" * 60)


def remove_consecutive_duplicates(df: pd.DataFrame) -> pd.DataFrame:
    """
    Remove consecutive duplicate AOI hits for each participant.

    Args:
        df (pd.DataFrame): Data with ParticipantID and AOIHit columns

    Returns:
        pd.DataFrame: Cleaned data with consecutive AOI duplicates removed
    """
    data_copy = df.copy()
    data_copy["lagged_AOIHit"] = data_copy.groupby("ParticipantID")["AOIHit"].shift(
        1,
        fill_value=np.nan,
    )
    cleaned = data_copy[data_copy["AOIHit"] != data_copy["lagged_AOIHit"]].drop(
        columns=["lagged_AOIHit"]
    )
    return cleaned.reset_index(drop=True)


def clean_sequences_for_chart_condition(chart_num: int, cond_num: int, data_directory: str) -> None:
    """
    Load, clean, and save eye tracking sequences for a given chart and condition.

    Args:
        chart_num (int): Chart number
        cond_num (int): Condition number
        data_directory (str): Directory containing input files
    """
    data_directory_path = Path(data_directory)
    input_file = data_directory_path / f"participants_condition{cond_num}_chart{chart_num}.xlsx"
    output_file = data_directory_path / f"cleaned_sequences_final_chart{chart_num}_cond_{cond_num}.csv"

    if not input_file.exists():
        print(f"Input file not found: {input_file}")
        return

    # Load and standardize input columns
    data = pd.read_excel(input_file)
    data.columns = ["ParticipantID", "ChartName", "AOIHit"]
    data["ParticipantID"] = data["ParticipantID"].astype(str).str.replace("P", "").astype(int)

    # Filter and order records before sequence cleanup
    data_filtered = data[data["AOIHit"] != "D"].copy()
    data_filtered = data_filtered.sort_values(["ParticipantID", "ChartName"])

    cleaned_sequences = remove_consecutive_duplicates(data_filtered)

    print("Cleaned sequences:")
    print(cleaned_sequences.head())
    cleaned_sequences.to_csv(output_file, index=False)
    print(f"Cleaned sequences have been saved to {output_file}")


def parse_args() -> argparse.Namespace:
    """
    Parse command-line arguments for selecting a processing workflow.
    """
    parser = argparse.ArgumentParser(description="Eye tracking data processing workflows")
    parser.add_argument(
        "--data-directory",
        default=None,
        help="Directory containing workflow input files (prompts if omitted)",
    )

    subparsers = parser.add_subparsers(dest="command")

    combine_parser = subparsers.add_parser(
        "combine",
        help="Combine participant files and create AOI abbreviations",
    )
    combine_parser.add_argument(
        "--participant-start",
        type=int,
        default=2,
        help="Starting participant number (inclusive)",
    )
    combine_parser.add_argument(
        "--participant-end",
        type=int,
        default=50,
        help="Ending participant number (exclusive)",
    )

    clean_parser = subparsers.add_parser(
        "clean",
        help="Clean chart/condition sequences and export CSV",
    )
    clean_parser.add_argument("--chart-num", type=int, required=True, help="Chart number")
    clean_parser.add_argument("--cond-num", type=int, required=True, help="Condition number")
    return parser.parse_args()


def main() -> None:
    """
    Execute the selected eye tracking data processing workflow.
    """
    args = parse_args()

    data_directory = args.data_directory
    if data_directory is None:
        data_directory = input("Enter the path to your data directory: ").strip() or "."

    command = args.command or "combine"

    if command == "combine":
        participant_range = (args.participant_start, args.participant_end)
        processor = EyeTrackingDataProcessor(
            data_directory=data_directory,
            participant_range=participant_range,
        )
        processor.process_all_data()
        return

    clean_sequences_for_chart_condition(
        chart_num=args.chart_num,
        cond_num=args.cond_num,
        data_directory=data_directory,
    )


if __name__ == "__main__":
    main()
