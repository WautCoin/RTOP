page 70002 "Palantir Dataset Card"
{
    Caption = 'Palantir Dataset';
    PageType = Card;
    SourceTable = "Palantir Dataset";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code identifying this dataset configuration.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a human-readable description for the dataset.';
                }
                field("Enabled"; Rec."Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether this dataset is included in synchronization runs.';
                }
            }
            group(Foundry)
            {
                Caption = 'Foundry';

                field("Dataset RID"; Rec."Dataset RID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Palantir Foundry resource identifier of the target dataset.';
                }
                field("Branch Name"; Rec."Branch Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Foundry dataset branch to write data to (default: master).';
                }
            }
            group(Source)
            {
                Caption = 'Source';

                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Business Central entity type that feeds this dataset.';
                }
            }
            group(SyncStatus)
            {
                Caption = 'Sync Status';

                field("Last Sync Date/Time"; Rec."Last Sync Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the date and time this dataset was last synchronized.';
                }
                field("Last Sync Status"; Rec."Last Sync Status")
                {
                    ApplicationArea = All;
                    StyleExpr = SyncStatusStyle;
                    ToolTip = 'Shows the result of the last synchronization attempt.';
                }
                field("Last Sync Error"; Rec."Last Sync Error")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Displays any error message from the last failed synchronization.';
                }
                field("Last Transaction ID"; Rec."Last Transaction ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the Foundry transaction identifier from the last synchronization.';
                }
                field("Record Count"; Rec."Record Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the number of records sent in the last synchronization.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncNow)
            {
                Caption = 'Sync Now';
                Image = Refresh;
                ApplicationArea = All;
                ToolTip = 'Synchronizes this dataset to Palantir Foundry immediately.';

                trigger OnAction()
                var
                    PalantirMgmt: Codeunit "Palantir Management";
                begin
                    PalantirMgmt.SyncDataset(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SyncNow_Promoted; SyncNow) { }
        }
    }

    var
        SyncStatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."Last Sync Status" of
            Rec."Last Sync Status"::Success:
                SyncStatusStyle := 'Favorable';
            Rec."Last Sync Status"::Failed:
                SyncStatusStyle := 'Unfavorable';
            Rec."Last Sync Status"::"In Progress":
                SyncStatusStyle := 'Ambiguous';
            else
                SyncStatusStyle := 'Standard';
        end;
    end;
}
