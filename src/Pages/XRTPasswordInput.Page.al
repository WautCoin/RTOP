page 50103 "XRT Password Input"
{
    Caption = 'Set XRT Password';
    PageType = StandardDialog;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'Credentials';

                field(Password; PasswordValue)
                {
                    ApplicationArea = All;
                    Caption = 'Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Enter the password for authenticating with the XRT service. The value is stored securely and cannot be viewed after saving.';
                }
            }
        }
    }

    procedure GetPassword(): SecretText
    begin
        exit(PasswordValue);
    end;

    var
        PasswordValue: SecretText;
}
