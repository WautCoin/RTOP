table 70001 "Palantir Dataset"
{
    Caption = 'Palantir Dataset';
    DataClassification = CustomerContent;
    LookupPageId = "Palantir Datasets";
    DrillDownPageId = "Palantir Datasets";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(10; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(11; "Dataset RID"; Text[250])
        {
            Caption = 'Dataset RID';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(12; "Branch Name"; Text[100])
        {
            Caption = 'Branch Name';
            DataClassification = SystemMetadata;
            InitValue = 'master';
        }
        field(20; "Source Type"; Option)
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
            OptionMembers = " ",Customer,Vendor,"Item","G/L Account","Sales Header","Purchase Header";
            OptionCaption = ' ,Customer,Vendor,Item,G/L Account,Sales Header,Purchase Header';
        }
        field(21; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
        field(30; "Last Transaction ID"; Text[100])
        {
            Caption = 'Last Transaction ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(31; "Last Sync Date/Time"; DateTime)
        {
            Caption = 'Last Sync Date/Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(32; "Last Sync Status"; Option)
        {
            Caption = 'Last Sync Status';
            DataClassification = SystemMetadata;
            OptionMembers = " ",Success,Failed,"In Progress";
            OptionCaption = ' ,Success,Failed,In Progress';
            Editable = false;
        }
        field(33; "Last Sync Error"; Text[500])
        {
            Caption = 'Last Sync Error';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; "Record Count"; Integer)
        {
            Caption = 'Record Count';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(SourceType; "Source Type", "Enabled") { }
    }

    trigger OnInsert()
    begin
        if "Branch Name" = '' then
            "Branch Name" := 'master';
    end;
}
