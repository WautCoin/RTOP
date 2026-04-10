table 50102 "XRT Bank Statement"
{
    Caption = 'XRT Bank Statement';
    DataClassification = CustomerContent;
    LookupPageId = "XRT Bank Statements";
    DrillDownPageId = "XRT Bank Statements";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account"."No.";
        }
        field(11; "Bank Account Name"; Text[100])
        {
            Caption = 'Bank Account Name';
            DataClassification = CustomerContent;
        }
        field(12; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
            DataClassification = CustomerContent;
        }
        field(13; "Statement No."; Text[50])
        {
            Caption = 'Statement No.';
            DataClassification = CustomerContent;
        }
        field(20; "Import Date"; Date)
        {
            Caption = 'Import Date';
            DataClassification = CustomerContent;
        }
        field(21; "Import Time"; Time)
        {
            Caption = 'Import Time';
            DataClassification = CustomerContent;
        }
        field(22; "Imported By"; Code[50])
        {
            Caption = 'Imported By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(30; Status; Enum "XRT Bank Stmt. Import Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(40; "Opening Balance"; Decimal)
        {
            Caption = 'Opening Balance';
            DataClassification = CustomerContent;
        }
        field(41; "Closing Balance"; Decimal)
        {
            Caption = 'Closing Balance';
            DataClassification = CustomerContent;
        }
        field(42; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }
        field(43; "No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            DataClassification = CustomerContent;
        }
        field(50; "File Name"; Text[250])
        {
            Caption = 'File Name';
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
        key(BankDate; "Bank Account No.", "Statement Date") { }
        key(Status; Status) { }
    }
}
