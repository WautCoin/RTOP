table 50101 "XRT Payment File"
{
    Caption = 'XRT Payment File';
    DataClassification = CustomerContent;
    LookupPageId = "XRT Payment Files";
    DrillDownPageId = "XRT Payment Files";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(11; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            DataClassification = CustomerContent;
        }
        field(12; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            DataClassification = CustomerContent;
        }
        field(13; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(20; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account"."No.";
        }
        field(21; "Bank Account Name"; Text[100])
        {
            Caption = 'Bank Account Name';
            DataClassification = CustomerContent;
        }
        field(30; Status; Enum "XRT Payment File Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(31; "File Format"; Enum "XRT Payment File Format")
        {
            Caption = 'File Format';
            DataClassification = CustomerContent;
        }
        field(40; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            DataClassification = CustomerContent;
        }
        field(41; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }
        field(42; "No. of Payments"; Integer)
        {
            Caption = 'No. of Payments';
            DataClassification = CustomerContent;
        }
        field(50; "XRT Reference"; Text[100])
        {
            Caption = 'XRT Reference';
            DataClassification = CustomerContent;
        }
        field(51; "XRT Status"; Text[50])
        {
            Caption = 'XRT Status';
            DataClassification = CustomerContent;
        }
        field(60; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(BankDate; "Bank Account No.", "Creation Date") { }
        key(Status; Status) { }
    }
}
