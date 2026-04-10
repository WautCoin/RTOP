codeunit 50100 "XRT Management"
{
    Caption = 'XRT Management';

    procedure TestConnection(var XRTSetup: Record "XRT Setup")
    var
        XRTAuthHelper: Codeunit "XRT Auth Helper";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        SuccessMsg: Label 'Connection to XRT service was successful.';
        FailedStatusErr: Label 'Connection to XRT service failed. Status code: %1.', Comment = '%1 = HTTP status code';
        UnreachableErr: Label 'Unable to reach the XRT service at %1. Verify the URL and network connectivity.', Comment = '%1 = service URL';
        EmptyUrlErr: Label 'Service URL must be filled in before testing the connection.';
    begin
        if XRTSetup."Service URL" = '' then
            Error(EmptyUrlErr);

        XRTAuthHelper.SetAuthorizationHeader(HttpClient, XRTSetup);
        if HttpClient.Get(XRTSetup."Service URL", HttpResponse) then begin
            if HttpResponse.IsSuccessStatusCode() then
                Message(SuccessMsg)
            else
                Error(FailedStatusErr, HttpResponse.HttpStatusCode());
        end else
            Error(UnreachableErr, XRTSetup."Service URL");
    end;

    procedure ExportPaymentFile(var GenJnlLine: Record "Gen. Journal Line")
    var
        XRTSetup: Record "XRT Setup";
        XRTFileExport: Codeunit "XRT File Export";
        XRTPaymentFile: Record "XRT Payment File";
        NotEnabledErr: Label 'XRT integration is not enabled. Please configure the XRT Setup first.';
    begin
        XRTSetup.GetRecordOnce();
        if not XRTSetup.Enabled then
            Error(NotEnabledErr);

        XRTFileExport.ExportPaymentJournalLines(GenJnlLine, XRTSetup, XRTPaymentFile);
    end;

    procedure RefreshPaymentFileStatus(var XRTPaymentFile: Record "XRT Payment File")
    var
        XRTSetup: Record "XRT Setup";
        XRTAuthHelper: Codeunit "XRT Auth Helper";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        RequestUrl: Text;
        ResponseText: Text;
        NoReferenceErr: Label 'No XRT Reference found for entry %1. The file may not have been sent yet.', Comment = '%1 = Entry No.';
    begin
        if XRTPaymentFile."XRT Reference" = '' then
            Error(NoReferenceErr, XRTPaymentFile."Entry No.");

        XRTSetup.GetRecordOnce();
        RequestUrl := XRTSetup."Service URL" + '/payments/' + XRTPaymentFile."XRT Reference" + '/status';

        XRTAuthHelper.SetAuthorizationHeader(HttpClient, XRTSetup);
        if HttpClient.Get(RequestUrl, HttpResponse) then begin
            HttpResponse.Content().ReadAs(ResponseText);
            UpdatePaymentFileStatusFromResponse(XRTPaymentFile, ResponseText);
        end;
    end;

    procedure CancelPaymentFile(var XRTPaymentFile: Record "XRT Payment File")
    var
        XRTSetup: Record "XRT Setup";
        XRTAuthHelper: Codeunit "XRT Auth Helper";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        RequestUrl: Text;
        ConfirmMsg: Label 'Do you want to cancel payment file %1?', Comment = '%1 = Entry No.';
        CancelledMsg: Label 'Payment file %1 has been successfully cancelled in XRT.', Comment = '%1 = Entry No.';
        FailedErr: Label 'Failed to cancel payment file %1 in XRT. Status code: %2.', Comment = '%1 = Entry No., %2 = HTTP status code';
        UnreachableErr: Label 'Unable to reach the XRT service while cancelling payment file %1.', Comment = '%1 = Entry No.';
    begin
        if not Confirm(ConfirmMsg, false, XRTPaymentFile."Entry No.") then
            exit;

        XRTSetup.GetRecordOnce();
        RequestUrl := XRTSetup."Service URL" + '/payments/' + XRTPaymentFile."XRT Reference" + '/cancel';

        XRTAuthHelper.SetAuthorizationHeader(HttpClient, XRTSetup);
        if HttpClient.Delete(RequestUrl, HttpResponse) then begin
            if HttpResponse.IsSuccessStatusCode() then begin
                XRTPaymentFile.Status := XRTPaymentFile.Status::Cancelled;
                XRTPaymentFile.Modify();
                Message(CancelledMsg, XRTPaymentFile."Entry No.");
            end else
                Error(FailedErr, XRTPaymentFile."Entry No.", HttpResponse.HttpStatusCode());
        end else
            Error(UnreachableErr, XRTPaymentFile."Entry No.");
    end;

    procedure ImportBankStatements()
    var
        XRTSetup: Record "XRT Setup";
        XRTFileExport: Codeunit "XRT File Export";
        NotEnabledErr: Label 'XRT integration is not enabled. Please configure the XRT Setup first.';
        ImportedMsg: Label '%1 bank statement(s) imported successfully.', Comment = '%1 = count';
        ImportCount: Integer;
    begin
        XRTSetup.GetRecordOnce();
        if not XRTSetup.Enabled then
            Error(NotEnabledErr);

        ImportCount := XRTFileExport.ImportBankStatementFiles(XRTSetup);
        Message(ImportedMsg, ImportCount);
    end;

    local procedure UpdatePaymentFileStatusFromResponse(var XRTPaymentFile: Record "XRT Payment File"; ResponseText: Text)
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        XRTStatusValue: Text;
    begin
        if not JsonObject.ReadFrom(ResponseText) then
            exit;

        if JsonObject.Get('status', JsonToken) then begin
            XRTStatusValue := JsonToken.AsValue().AsText();
            XRTPaymentFile."XRT Status" := CopyStr(XRTStatusValue, 1, MaxStrLen(XRTPaymentFile."XRT Status"));
            case UpperCase(XRTStatusValue) of
                'ACKNOWLEDGED', 'ACCEPTED':
                    XRTPaymentFile.Status := XRTPaymentFile.Status::Acknowledged;
                'REJECTED':
                    XRTPaymentFile.Status := XRTPaymentFile.Status::Rejected;
                'CANCELLED':
                    XRTPaymentFile.Status := XRTPaymentFile.Status::Cancelled;
            end;
            XRTPaymentFile.Modify();
        end;
    end;
}
