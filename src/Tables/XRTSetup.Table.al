table 50100 "XRT Setup"
{
    Caption = 'XRT Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
            DataClassification = CustomerContent;
        }
        field(11; "Company ID"; Text[50])
        {
            Caption = 'Company ID';
            DataClassification = CustomerContent;
        }
        field(12; "User Name"; Text[100])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Has Password"; Boolean)
        {
            Caption = 'Has Password';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Export Path"; Text[250])
        {
            Caption = 'Export Path';
            DataClassification = CustomerContent;
        }
        field(21; "Import Path"; Text[250])
        {
            Caption = 'Import Path';
            DataClassification = CustomerContent;
        }
        field(30; "Payment File Format"; Enum "XRT Payment File Format")
        {
            Caption = 'Payment File Format';
            DataClassification = CustomerContent;
        }
        field(31; "Bank Statement Format"; Enum "XRT Bank Stmt. Format")
        {
            Caption = 'Bank Statement Format';
            DataClassification = CustomerContent;
        }
        field(40; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
        }
        field(41; "Log Entries"; Boolean)
        {
            Caption = 'Log Entries';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetRecordOnce()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    procedure SetPassword(Password: SecretText)
    var
        XRTAuthHelper: Codeunit "XRT Auth Helper";
    begin
        XRTAuthHelper.SetPassword(Password);
        "Has Password" := true;
        Modify();
    end;

    procedure DeletePassword()
    var
        XRTAuthHelper: Codeunit "XRT Auth Helper";
    begin
        XRTAuthHelper.DeletePassword();
        "Has Password" := false;
        Modify();
    end;
}
