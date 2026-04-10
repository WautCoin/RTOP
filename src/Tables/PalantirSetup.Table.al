table 70000 "Palantir Setup"
{
    Caption = 'Palantir Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Foundry URL"; Text[250])
        {
            Caption = 'Foundry URL';
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            begin
                if "Foundry URL" <> '' then
                    if not "Foundry URL".StartsWith('https://') then
                        Error(MustUseHttpsErr, FieldCaption("Foundry URL"));
            end;
        }
        field(11; "API Token"; Text[500])
        {
            Caption = 'API Token';
            DataClassification = EndUserPseudonymousIdentifiers;
            ExtendedDatatype = Masked;
        }
        field(12; "Compass Project RID"; Text[250])
        {
            Caption = 'Compass Project RID';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(20; "Auto Sync Enabled"; Boolean)
        {
            Caption = 'Auto Sync Enabled';
            DataClassification = SystemMetadata;
        }
        field(21; "Sync Interval (Hours)"; Integer)
        {
            Caption = 'Sync Interval (Hours)';
            DataClassification = SystemMetadata;
            MinValue = 1;
            MaxValue = 168;
            InitValue = 24;
        }
        field(22; "Last Sync Date/Time"; DateTime)
        {
            Caption = 'Last Sync Date/Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(30; "Connection Status"; Option)
        {
            Caption = 'Connection Status';
            DataClassification = SystemMetadata;
            OptionMembers = " ",Connected,Failed;
            OptionCaption = ' ,Connected,Failed';
            Editable = false;
        }
        field(31; "Connection Tested At"; DateTime)
        {
            Caption = 'Connection Tested At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        MustUseHttpsErr: Label 'The %1 must begin with ''https://''.';

    procedure GetOrCreate(): Record "Palantir Setup"
    var
        PalantirSetup: Record "Palantir Setup";
    begin
        if not PalantirSetup.Get('') then begin
            PalantirSetup.Init();
            PalantirSetup."Primary Key" := '';
            PalantirSetup.Insert(true);
        end;
        exit(PalantirSetup);
    end;
}
