codeunit 70000 "Palantir Management"
{
    Access = Public;

    var
        PalantirAPI: Codeunit "Palantir API Integration";
        ConnectionSuccessMsg: Label 'Connection to Palantir Foundry was successful.';
        ConnectionFailedMsg: Label 'Connection to Palantir Foundry failed. Please check the URL and API Token in the Palantir Setup.';
        SyncCompletedMsg: Label 'Synchronization of dataset %1 completed successfully. %2 record(s) sent.';
        SyncAllCompletedMsg: Label 'All enabled datasets have been synchronized.';
        NoEnabledDatasetsMsg: Label 'No enabled datasets found. Please configure at least one dataset in the Palantir Datasets list.';

    // -------------------------------------------------------------------------
    // Connection
    // -------------------------------------------------------------------------

    procedure TestConnection(var PalantirSetup: Record "Palantir Setup")
    begin
        if PalantirAPI.TestConnection() then begin
            PalantirSetup."Connection Status" := PalantirSetup."Connection Status"::Connected;
            PalantirSetup."Connection Tested At" := CurrentDateTime();
            PalantirSetup.Modify(true);
            Message(ConnectionSuccessMsg);
        end else begin
            PalantirSetup."Connection Status" := PalantirSetup."Connection Status"::Failed;
            PalantirSetup."Connection Tested At" := CurrentDateTime();
            PalantirSetup.Modify(true);
            Message(ConnectionFailedMsg);
        end;
    end;

    // -------------------------------------------------------------------------
    // Dataset synchronization
    // -------------------------------------------------------------------------

    procedure SyncAllDatasets()
    var
        PalantirDataset: Record "Palantir Dataset";
    begin
        PalantirDataset.SetRange("Enabled", true);
        if PalantirDataset.IsEmpty() then begin
            Message(NoEnabledDatasetsMsg);
            exit;
        end;

        if PalantirDataset.FindSet() then
            repeat
                SyncDataset(PalantirDataset);
            until PalantirDataset.Next() = 0;

        Message(SyncAllCompletedMsg);
    end;

    procedure SyncDataset(var PalantirDataset: Record "Palantir Dataset")
    var
        PalantirSetup: Record "Palantir Setup";
        JsonLines: Text;
        DatasetRID: Text;
        TransactionRID: Text;
        RecordCount: Integer;
    begin
        PalantirSetup := PalantirSetup.GetOrCreate();

        // Ensure the dataset has a Foundry RID; create it if missing
        if PalantirDataset."Dataset RID" = '' then begin
            DatasetRID := PalantirAPI.CreateOrGetDataset(
                PalantirDataset."Description",
                PalantirSetup."Compass Project RID");
            PalantirDataset."Dataset RID" := DatasetRID;
            PalantirDataset.Modify(true);
        end;

        PalantirDataset."Last Sync Status" := PalantirDataset."Last Sync Status"::"In Progress";
        PalantirDataset."Last Sync Error" := '';
        PalantirDataset.Modify(true);
        Commit(); // Persist in-progress status before the API calls

        TransactionRID := '';
        if TrySyncDataset(PalantirDataset, JsonLines, TransactionRID, RecordCount) then begin
            PalantirDataset."Last Sync Status" := PalantirDataset."Last Sync Status"::Success;
            PalantirDataset."Last Sync Error" := '';
            PalantirDataset."Last Sync Date/Time" := CurrentDateTime();
            PalantirDataset."Last Transaction ID" := TransactionRID;
            PalantirDataset."Record Count" := RecordCount;
            PalantirDataset.Modify(true);

            PalantirSetup."Last Sync Date/Time" := CurrentDateTime();
            PalantirSetup.Modify(true);

            Message(SyncCompletedMsg, PalantirDataset.Code, RecordCount);
        end else begin
            PalantirDataset."Last Sync Status" := PalantirDataset."Last Sync Status"::Failed;
            PalantirDataset."Last Sync Error" := CopyStr(GetLastErrorText(), 1, 500);
            PalantirDataset."Last Sync Date/Time" := CurrentDateTime();
            PalantirDataset.Modify(true);
        end;
    end;

    [TryFunction]
    local procedure TrySyncDataset(var PalantirDataset: Record "Palantir Dataset"; var JsonLines: Text; var TransactionRID: Text; var RecordCount: Integer)
    var
        BranchName: Text;
    begin
        BranchName := PalantirDataset."Branch Name";
        if BranchName = '' then
            BranchName := 'master';

        TransactionRID := PalantirAPI.StartTransaction(PalantirDataset."Dataset RID", BranchName);

        CollectDataAsJsonLines(PalantirDataset, JsonLines, RecordCount);

        PalantirAPI.UploadParquetFile(
            PalantirDataset."Dataset RID",
            TransactionRID,
            'data.jsonl',
            JsonLines);

        PalantirAPI.CommitTransaction(PalantirDataset."Dataset RID", TransactionRID);
    end;

    // -------------------------------------------------------------------------
    // Data collection – builds a newline-delimited JSON (JSONL) payload
    // -------------------------------------------------------------------------

    local procedure CollectDataAsJsonLines(var PalantirDataset: Record "Palantir Dataset"; var JsonLines: Text; var RecordCount: Integer)
    begin
        RecordCount := 0;
        JsonLines := '';

        case PalantirDataset."Source Type" of
            PalantirDataset."Source Type"::Customer:
                CollectCustomers(JsonLines, RecordCount);
            PalantirDataset."Source Type"::Vendor:
                CollectVendors(JsonLines, RecordCount);
            PalantirDataset."Source Type"::Item:
                CollectItems(JsonLines, RecordCount);
            PalantirDataset."Source Type"::"G/L Account":
                CollectGLAccounts(JsonLines, RecordCount);
            else
                Error('Source type %1 is not supported.', PalantirDataset."Source Type");
        end;
    end;

    local procedure CollectCustomers(var JsonLines: Text; var RecordCount: Integer)
    var
        Customer: Record Customer;
        JsonObj: JsonObject;
        JsonLine: Text;
    begin
        if Customer.FindSet() then
            repeat
                Clear(JsonObj);
                JsonObj.Add('no', Customer."No.");
                JsonObj.Add('name', Customer.Name);
                JsonObj.Add('city', Customer.City);
                JsonObj.Add('countryRegionCode', Customer."Country/Region Code");
                JsonObj.Add('currencyCode', Customer."Currency Code");
                JsonObj.Add('balance', Customer."Balance (LCY)");
                JsonObj.Add('balanceDue', Customer."Balance Due (LCY)");
                JsonObj.Add('blocked', Format(Customer.Blocked));
                JsonObj.WriteTo(JsonLine);
                AppendJsonLine(JsonLines, JsonLine);
                RecordCount += 1;
            until Customer.Next() = 0;
    end;

    local procedure CollectVendors(var JsonLines: Text; var RecordCount: Integer)
    var
        Vendor: Record Vendor;
        JsonObj: JsonObject;
        JsonLine: Text;
    begin
        if Vendor.FindSet() then
            repeat
                Clear(JsonObj);
                JsonObj.Add('no', Vendor."No.");
                JsonObj.Add('name', Vendor.Name);
                JsonObj.Add('city', Vendor.City);
                JsonObj.Add('countryRegionCode', Vendor."Country/Region Code");
                JsonObj.Add('currencyCode', Vendor."Currency Code");
                JsonObj.Add('balance', Vendor."Balance (LCY)");
                JsonObj.Add('balanceDue', Vendor."Balance Due (LCY)");
                JsonObj.Add('blocked', Format(Vendor.Blocked));
                JsonObj.WriteTo(JsonLine);
                AppendJsonLine(JsonLines, JsonLine);
                RecordCount += 1;
            until Vendor.Next() = 0;
    end;

    local procedure CollectItems(var JsonLines: Text; var RecordCount: Integer)
    var
        Item: Record Item;
        JsonObj: JsonObject;
        JsonLine: Text;
    begin
        if Item.FindSet() then
            repeat
                Clear(JsonObj);
                JsonObj.Add('no', Item."No.");
                JsonObj.Add('description', Item.Description);
                JsonObj.Add('type', Format(Item.Type));
                JsonObj.Add('unitPrice', Item."Unit Price");
                JsonObj.Add('unitCost', Item."Unit Cost");
                JsonObj.Add('inventory', Item.Inventory);
                JsonObj.Add('baseUnitOfMeasure', Item."Base Unit of Measure");
                JsonObj.Add('blocked', Item.Blocked);
                JsonObj.WriteTo(JsonLine);
                AppendJsonLine(JsonLines, JsonLine);
                RecordCount += 1;
            until Item.Next() = 0;
    end;

    local procedure CollectGLAccounts(var JsonLines: Text; var RecordCount: Integer)
    var
        GLAccount: Record "G/L Account";
        JsonObj: JsonObject;
        JsonLine: Text;
    begin
        if GLAccount.FindSet() then
            repeat
                Clear(JsonObj);
                JsonObj.Add('no', GLAccount."No.");
                JsonObj.Add('name', GLAccount.Name);
                JsonObj.Add('accountType', Format(GLAccount."Account Type"));
                JsonObj.Add('accountCategory', Format(GLAccount."Account Category"));
                JsonObj.Add('netChange', GLAccount."Net Change");
                JsonObj.Add('balance', GLAccount.Balance);
                JsonObj.Add('blocked', GLAccount.Blocked);
                JsonObj.WriteTo(JsonLine);
                AppendJsonLine(JsonLines, JsonLine);
                RecordCount += 1;
            until GLAccount.Next() = 0;
    end;

    local procedure AppendJsonLine(var JsonLines: Text; NewLine: Text)
    begin
        if JsonLines <> '' then
            JsonLines += #10;
        JsonLines += NewLine;
    end;
}
