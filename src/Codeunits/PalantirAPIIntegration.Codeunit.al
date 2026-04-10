codeunit 70001 "Palantir API Integration"
{
    Access = Internal;

    // -------------------------------------------------------------------------
    // Palantir Foundry Datasets API
    // Docs: https://www.palantir.com/docs/foundry/api/datasets-resources/datasets/
    // -------------------------------------------------------------------------

    var
        PalantirSetup: Record "Palantir Setup";
        SetupLoaded: Boolean;
        NotConfiguredErr: Label 'Palantir Setup is not configured. Please open the Palantir Setup page and provide a Foundry URL and API Token.';
        HttpRequestFailedErr: Label 'Palantir API request failed with status %1: %2';
        ContentTypeJsonLbl: Label 'application/json', Locked = true;
        AuthorizationHeaderLbl: Label 'Authorization', Locked = true;
        BearerPrefixLbl: Label 'Bearer ', Locked = true;

    // -------------------------------------------------------------------------
    // Connection test
    // -------------------------------------------------------------------------

    procedure TestConnection(): Boolean
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        RequestUrl: Text;
    begin
        EnsureSetup();
        RequestUrl := PalantirSetup."Foundry URL" + '/api/v1/datasets?pageSize=1';
        AddAuthHeader(HttpClient);
        if not HttpClient.Get(RequestUrl, HttpResponse) then
            exit(false);
        exit(HttpResponse.IsSuccessStatusCode());
    end;

    // -------------------------------------------------------------------------
    // Dataset operations
    // -------------------------------------------------------------------------

    procedure CreateOrGetDataset(DatasetName: Text; ProjectRID: Text): Text
    var
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestUrl: Text;
        RequestBody: Text;
        ResponseBody: Text;
        DatasetRID: Text;
    begin
        EnsureSetup();
        RequestUrl := PalantirSetup."Foundry URL" + '/api/v1/datasets';
        RequestBody := StrSubstNo('{"name":"%1","parentFolderRid":"%2"}', EscapeJson(DatasetName), EscapeJson(ProjectRID));

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', ContentTypeJsonLbl);

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(RequestUrl);
        HttpRequest.Content := HttpContent;
        AddAuthHeader(HttpClient);

        if not HttpClient.Send(HttpRequest, HttpResponse) then
            Error(HttpRequestFailedErr, 0, 'Connection failed');

        CheckResponseSuccess(HttpResponse);
        HttpResponse.Content().ReadAs(ResponseBody);
        DatasetRID := ExtractJsonText(ResponseBody, 'rid');
        exit(DatasetRID);
    end;

    procedure StartTransaction(DatasetRID: Text; BranchName: Text): Text
    var
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestUrl: Text;
        RequestBody: Text;
        ResponseBody: Text;
        TransactionRID: Text;
    begin
        EnsureSetup();
        RequestUrl := StrSubstNo('%1/api/v1/datasets/%2/transactions',
            PalantirSetup."Foundry URL", EscapeUrl(DatasetRID));
        RequestBody := StrSubstNo('{"branchId":"%1","type":"APPEND"}', EscapeJson(BranchName));

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', ContentTypeJsonLbl);

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(RequestUrl);
        HttpRequest.Content := HttpContent;
        AddAuthHeader(HttpClient);

        if not HttpClient.Send(HttpRequest, HttpResponse) then
            Error(HttpRequestFailedErr, 0, 'Connection failed');

        CheckResponseSuccess(HttpResponse);
        HttpResponse.Content().ReadAs(ResponseBody);
        TransactionRID := ExtractJsonText(ResponseBody, 'rid');
        exit(TransactionRID);
    end;

    procedure UploadJsonLinesFile(DatasetRID: Text; TransactionRID: Text; LogicalPath: Text; JsonLines: Text)
    var
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestUrl: Text;
    begin
        EnsureSetup();
        RequestUrl := StrSubstNo(
            '%1/api/v1/datasets/%2/files:upload?transactionRid=%3&logicalPath=%4',
            PalantirSetup."Foundry URL",
            EscapeUrl(DatasetRID),
            EscapeUrl(TransactionRID),
            EscapeUrl(LogicalPath));

        HttpContent.WriteFrom(JsonLines);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/octet-stream');

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(RequestUrl);
        HttpRequest.Content := HttpContent;
        AddAuthHeader(HttpClient);

        if not HttpClient.Send(HttpRequest, HttpResponse) then
            Error(HttpRequestFailedErr, 0, 'Connection failed');

        CheckResponseSuccess(HttpResponse);
    end;

    procedure CommitTransaction(DatasetRID: Text; TransactionRID: Text)
    var
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestUrl: Text;
    begin
        EnsureSetup();
        RequestUrl := StrSubstNo(
            '%1/api/v1/datasets/%2/transactions/%3/commit',
            PalantirSetup."Foundry URL",
            EscapeUrl(DatasetRID),
            EscapeUrl(TransactionRID));

        HttpContent.WriteFrom('{}');
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', ContentTypeJsonLbl);

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(RequestUrl);
        HttpRequest.Content := HttpContent;
        AddAuthHeader(HttpClient);

        if not HttpClient.Send(HttpRequest, HttpResponse) then
            Error(HttpRequestFailedErr, 0, 'Connection failed');

        CheckResponseSuccess(HttpResponse);
    end;

    procedure AbortTransaction(DatasetRID: Text; TransactionRID: Text)
    var
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestUrl: Text;
    begin
        EnsureSetup();
        RequestUrl := StrSubstNo(
            '%1/api/v1/datasets/%2/transactions/%3/abort',
            PalantirSetup."Foundry URL",
            EscapeUrl(DatasetRID),
            EscapeUrl(TransactionRID));

        HttpContent.WriteFrom('{}');
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', ContentTypeJsonLbl);

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(RequestUrl);
        HttpRequest.Content := HttpContent;
        AddAuthHeader(HttpClient);

        // Best effort – ignore errors when aborting
        if HttpClient.Send(HttpRequest, HttpResponse) then;
    end;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    local procedure EnsureSetup()
    begin
        if SetupLoaded then
            exit;
        PalantirSetup := PalantirSetup.GetOrCreate();
        if (PalantirSetup."Foundry URL" = '') or (PalantirSetup."API Token" = '') then
            Error(NotConfiguredErr);
        SetupLoaded := true;
    end;

    local procedure AddAuthHeader(var HttpClient: HttpClient)
    var
        DefaultRequestHeaders: HttpHeaders;
    begin
        HttpClient.DefaultRequestHeaders(DefaultRequestHeaders);
        if DefaultRequestHeaders.Contains(AuthorizationHeaderLbl) then
            DefaultRequestHeaders.Remove(AuthorizationHeaderLbl);
        DefaultRequestHeaders.Add(AuthorizationHeaderLbl, BearerPrefixLbl + PalantirSetup."API Token");
    end;

    local procedure CheckResponseSuccess(HttpResponse: HttpResponseMessage)
    var
        ResponseBody: Text;
        StatusCode: Integer;
    begin
        if HttpResponse.IsSuccessStatusCode() then
            exit;
        StatusCode := HttpResponse.HttpStatusCode();
        HttpResponse.Content().ReadAs(ResponseBody);
        Error(HttpRequestFailedErr, StatusCode, ResponseBody);
    end;

    local procedure EscapeJson(Value: Text): Text
    begin
        Value := Value.Replace('\', '\\');
        Value := Value.Replace('"', '\"');

        Value := Value.Replace(#10, '\n');
        Value := Value.Replace(#13, '\r');
        Value := Value.Replace(#09, '\t');
        exit(Value);
    end;

    local procedure EscapeUrl(Value: Text): Text
    begin
        // Minimal URL encoding for path segments containing RIDs
        Value := Value.Replace('/', '%2F');
        exit(Value);
    end;

    local procedure ExtractJsonText(JsonText: Text; FieldName: Text): Text
    var
        JsonObj: JsonObject;
        JsonVal: JsonValue;
        JsonToken: JsonToken;
    begin
        if not JsonObj.ReadFrom(JsonText) then
            exit('');
        if not JsonObj.Get(FieldName, JsonToken) then
            exit('');
        JsonVal := JsonToken.AsValue();
        exit(JsonVal.AsText());
    end;
}
