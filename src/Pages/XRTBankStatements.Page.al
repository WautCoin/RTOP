page 50102 "XRT Bank Statements"
{
    Caption = 'XRT Bank Statements';
    PageType = List;
    SourceTable = "XRT Bank Statement";
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
                    ToolTip = 'Specifies the unique entry number of the bank statement record.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bank account number for this statement.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bank account name for this statement.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of the bank statement.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the statement number assigned by the bank or XRT.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Specifies the import status of the bank statement.';
                }
                field("Opening Balance"; Rec."Opening Balance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the opening balance reported on the bank statement.';
                }
                field("Closing Balance"; Rec."Closing Balance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the closing balance reported on the bank statement.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the bank statement.';
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of transaction lines in the bank statement.';
                }
                field("Import Date"; Rec."Import Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the bank statement was imported from XRT.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the file imported from XRT.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1; Notes) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImportStatements)
            {
                Caption = 'Import Bank Statements';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Imports new bank statement files from the XRT import path.';

                trigger OnAction()
                var
                    XRTMgt: Codeunit "XRT Management";
                begin
                    XRTMgt.ImportBankStatements();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ImportStatements_Promoted; ImportStatements) { }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::Posted:
                StatusStyle := 'Favorable';
            Rec.Status::Imported:
                StatusStyle := 'StrongAccent';
            else
                StatusStyle := 'None';
        end;
    end;
}
