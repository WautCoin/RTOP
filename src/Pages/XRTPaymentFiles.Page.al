page 50101 "XRT Payment Files"
{
    Caption = 'XRT Payment Files';
    PageType = List;
    SourceTable = "XRT Payment File";
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number of the payment file record.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the payment file exported to XRT.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bank account number used for this payment file.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bank account name used for this payment file.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the payment file was created.';
                }
                field("File Format"; Rec."File Format")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the format of the payment file.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Specifies the current status of the payment file.';
                }
                field("No. of Payments"; Rec."No. of Payments")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of individual payments contained in the file.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of all payments in the file.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the payment file.';
                }
                field("XRT Reference"; Rec."XRT Reference")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference assigned by XRT after the file has been received.';
                }
                field("XRT Status"; Rec."XRT Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the processing status returned by XRT.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1; Notes) { ApplicationArea = All; }
            systempart(Control2; Links) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshStatus)
            {
                Caption = 'Refresh Status';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Retrieves the latest processing status for the selected payment file from XRT.';

                trigger OnAction()
                var
                    XRTMgt: Codeunit "XRT Management";
                begin
                    XRTMgt.RefreshPaymentFileStatus(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelFile)
            {
                Caption = 'Cancel File';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Cancels the selected payment file in XRT.';
                Enabled = Rec.Status = Rec.Status::Sent;

                trigger OnAction()
                var
                    XRTMgt: Codeunit "XRT Management";
                begin
                    XRTMgt.CancelPaymentFile(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RefreshStatus_Promoted; RefreshStatus) { }
            actionref(CancelFile_Promoted; CancelFile) { }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Rejected:
                StatusStyle := 'Unfavorable';
            Rec.Status::Acknowledged:
                StatusStyle := 'Favorable';
            Rec.Status::Cancelled:
                StatusStyle := 'Attention';
            else
                StatusStyle := 'None';
        end;
    end;
}
