page 70000 "Palantir Setup Card"
{
    Caption = 'Palantir Setup';
    PageType = Card;
    SourceTable = "Palantir Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Connection';

                field("Foundry URL"; Rec."Foundry URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL of your Palantir Foundry instance (e.g. https://your-org.palantirfoundry.com).';
                }
                field("API Token"; Rec."API Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bearer token used to authenticate against the Palantir Foundry API.';
                }
                field("Compass Project RID"; Rec."Compass Project RID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Compass project resource identifier where datasets will be created.';
                }
                field("Connection Status"; Rec."Connection Status")
                {
                    ApplicationArea = All;
                    StyleExpr = ConnectionStatusStyle;
                    ToolTip = 'Indicates whether the last connection test to Palantir Foundry succeeded.';
                }
                field("Connection Tested At"; Rec."Connection Tested At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the date and time the connection was last tested.';
                }
            }
            group(Synchronization)
            {
                Caption = 'Synchronization';

                field("Auto Sync Enabled"; Rec."Auto Sync Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether datasets are automatically synchronized on a scheduled basis.';
                }
                field("Sync Interval (Hours)"; Rec."Sync Interval (Hours)")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Auto Sync Enabled";
                    ToolTip = 'Specifies how often (in hours) the automatic synchronization job runs.';
                }
                field("Last Sync Date/Time"; Rec."Last Sync Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows when the last scheduled synchronization was run.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                Caption = 'Test Connection';
                Image = TestFile;
                ApplicationArea = All;
                ToolTip = 'Sends a test request to Palantir Foundry to verify the connection settings.';

                trigger OnAction()
                var
                    PalantirMgmt: Codeunit "Palantir Management";
                begin
                    PalantirMgmt.TestConnection(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(SyncAllNow)
            {
                Caption = 'Sync All Datasets Now';
                Image = RefreshLines;
                ApplicationArea = All;
                ToolTip = 'Immediately triggers a synchronization of all enabled Palantir datasets.';

                trigger OnAction()
                var
                    PalantirMgmt: Codeunit "Palantir Management";
                begin
                    PalantirMgmt.SyncAllDatasets();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Datasets)
            {
                Caption = 'Datasets';
                Image = DataEntry;
                RunObject = Page "Palantir Datasets";
                ApplicationArea = All;
                ToolTip = 'Opens the list of configured Palantir Foundry datasets.';
            }
        }
        area(Promoted)
        {
            actionref(TestConnection_Promoted; TestConnection) { }
            actionref(SyncAllNow_Promoted; SyncAllNow) { }
            actionref(Datasets_Promoted; Datasets) { }
        }
    }

    var
        ConnectionStatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."Connection Status" of
            Rec."Connection Status"::Connected:
                ConnectionStatusStyle := 'Favorable';
            Rec."Connection Status"::Failed:
                ConnectionStatusStyle := 'Unfavorable';
            else
                ConnectionStatusStyle := 'Standard';
        end;
    end;

    trigger OnOpenPage()
    var
        PalantirSetup: Record "Palantir Setup";
    begin
        PalantirSetup.GetOrCreate();
        if not Rec.Get('') then
            Rec.Get('');
    end;
}
