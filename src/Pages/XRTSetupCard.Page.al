page 50100 "XRT Setup Card"
{
    Caption = 'XRT Setup';
    PageType = Card;
    SourceTable = "XRT Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the XRT integration is enabled.';
                }
                field("Log Entries"; Rec."Log Entries")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log all XRT integration entries for auditing.';
                }
            }
            group(Connection)
            {
                Caption = 'Connection';

                field("Service URL"; Rec."Service URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL of the XRT web service endpoint.';
                }
                field("Company ID"; Rec."Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company identifier used to authenticate with XRT.';
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user name for authenticating with the XRT service.';
                }
                field("Has Password"; Rec."Has Password")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether a password has been stored securely for XRT authentication.';
                }
            }
            group(FilePaths)
            {
                Caption = 'File Paths';

                field("Export Path"; Rec."Export Path")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the folder path where payment files are exported for XRT pickup.';
                }
                field("Import Path"; Rec."Import Path")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the folder path from which bank statement files are imported from XRT.';
                }
            }
            group(Formats)
            {
                Caption = 'Formats';

                field("Payment File Format"; Rec."Payment File Format")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default format for payment files exported to XRT.';
                }
                field("Bank Statement Format"; Rec."Bank Statement Format")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default format for bank statement files imported from XRT.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetPassword)
            {
                Caption = 'Set Password';
                ApplicationArea = All;
                Image = Password;
                ToolTip = 'Stores the XRT service password securely using isolated storage.';

                trigger OnAction()
                var
                    XRTPasswordInput: Page "XRT Password Input";
                begin
                    XRTPasswordInput.LookupMode(true);
                    if XRTPasswordInput.RunModal() = Action::LookupOK then begin
                        Rec.SetPassword(XRTPasswordInput.GetPassword());
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ClearPassword)
            {
                Caption = 'Clear Password';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Removes the stored XRT service password from isolated storage.';
                Enabled = Rec."Has Password";

                trigger OnAction()
                var
                    ConfirmMsg: Label 'Do you want to remove the stored XRT password?';
                begin
                    if Confirm(ConfirmMsg, false) then begin
                        Rec.DeletePassword();
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(TestConnection)
            {
                Caption = 'Test Connection';
                ApplicationArea = All;
                Image = TestFile;
                ToolTip = 'Tests the connection to the XRT service using the current settings.';

                trigger OnAction()
                var
                    XRTMgt: Codeunit "XRT Management";
                begin
                    XRTMgt.TestConnection(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetPassword_Promoted; SetPassword) { }
            actionref(TestConnection_Promoted; TestConnection) { }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetRecordOnce();
    end;
}
