page 70001 "Palantir Datasets"
{
    Caption = 'Palantir Datasets';
    PageType = List;
    SourceTable = "Palantir Dataset";
    UsageCategory = Lists;
    ApplicationArea = All;
    CardPageId = "Palantir Dataset Card";

    layout
    {
        area(Content)
        {
            repeater(Datasets)
            {
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
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Business Central entity type that feeds this dataset.';
                }
                field("Enabled"; Rec."Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether this dataset is included in synchronization runs.';
                }
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
                field("Record Count"; Rec."Record Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the number of records sent in the last synchronization.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = RecordLinks; }
            systempart(Notes; Notes) { ApplicationArea = Notes; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncSelected)
            {
                Caption = 'Sync Now';
                Image = Refresh;
                ApplicationArea = All;
                ToolTip = 'Synchronizes the selected dataset to Palantir Foundry immediately.';

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
            actionref(SyncSelected_Promoted; SyncSelected) { }
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
