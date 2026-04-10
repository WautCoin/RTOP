codeunit 50101 "XRT File Export"
{
    Caption = 'XRT File Export';

    procedure ExportPaymentJournalLines(var GenJnlLine: Record "Gen. Journal Line"; XRTSetup: Record "XRT Setup"; var XRTPaymentFile: Record "XRT Payment File")
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        FileName: Text;
        ExportedCount: Integer;
        NothingToExportErr: Label 'There are no journal lines to export.';
    begin
        if GenJnlLine.IsEmpty() then
            Error(NothingToExportErr);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);

        case XRTSetup."Payment File Format" of
            XRTSetup."Payment File Format"::SEPA,
            XRTSetup."Payment File Format"::"PAIN.001":
                ExportedCount := BuildPain001Xml(GenJnlLine, XRTSetup, OutStream);
            XRTSetup."Payment File Format"::"Swift MT101":
                ExportedCount := BuildSwiftMT101(GenJnlLine, XRTSetup, OutStream);
            else
                ExportedCount := BuildPain001Xml(GenJnlLine, XRTSetup, OutStream);
        end;

        FileName := GetPaymentFileName(XRTSetup."Payment File Format");
        CreatePaymentFileRecord(XRTPaymentFile, GenJnlLine, XRTSetup, FileName, ExportedCount);
        DownloadPaymentFile(TempBlob, FileName);
    end;

    procedure ImportBankStatementFiles(XRTSetup: Record "XRT Setup"): Integer
    var
        ImportCount: Integer;
    begin
        ImportCount := 0;
        ImportCount += ImportStatementsFromAPI(XRTSetup);
        exit(ImportCount);
    end;

    local procedure BuildPain001Xml(var GenJnlLine: Record "Gen. Journal Line"; XRTSetup: Record "XRT Setup"; var OutStream: OutStream): Integer
    var
        XmlDoc: XmlDocument;
        XmlDecl: XmlDeclaration;
        DocumentNode: XmlElement;
        CstmrNode: XmlElement;
        GrpHdrNode: XmlElement;
        PmtInfNode: XmlElement;
        CdtTrfTxInfNode: XmlElement;
        ExportCount: Integer;
        MsgId: Text;
        CreDtTm: Text;
    begin
        MsgId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 35);
        CreDtTm := Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>');

        XmlDoc := XmlDocument.Create();
        XmlDecl := XmlDeclaration.Create('1.0', 'UTF-8', '');
        XmlDoc.SetDeclaration(XmlDecl);

        DocumentNode := XmlElement.Create('Document', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03');
        CstmrNode := XmlElement.Create('CstmrCdtTrfInitn');
        DocumentNode.Add(CstmrNode);
        XmlDoc.Add(DocumentNode);

        GrpHdrNode := XmlElement.Create('GrpHdr');
        GrpHdrNode.Add(XmlElement.Create('MsgId', MsgId));
        GrpHdrNode.Add(XmlElement.Create('CreDtTm', CreDtTm));
        GrpHdrNode.Add(XmlElement.Create('NbOfTxs', '0'));
        GrpHdrNode.Add(XmlElement.Create('CtrlSum', '0'));
        CstmrNode.Add(GrpHdrNode);

        ExportCount := 0;
        if GenJnlLine.FindSet() then
            repeat
                PmtInfNode := XmlElement.Create('PmtInf');
                AddPmtInfNode(PmtInfNode, GenJnlLine, XRTSetup);
                CdtTrfTxInfNode := XmlElement.Create('CdtTrfTxInf');
                AddCdtTrfTxInfNode(CdtTrfTxInfNode, GenJnlLine);
                PmtInfNode.Add(CdtTrfTxInfNode);
                CstmrNode.Add(PmtInfNode);
                ExportCount += 1;
            until GenJnlLine.Next() = 0;

        XmlDoc.WriteTo(OutStream);
        exit(ExportCount);
    end;

    local procedure AddPmtInfNode(var PmtInfNode: XmlElement; GenJnlLine: Record "Gen. Journal Line"; XRTSetup: Record "XRT Setup")
    begin
        PmtInfNode.Add(XmlElement.Create('PmtInfId', Format(GenJnlLine."Line No.")));
        PmtInfNode.Add(XmlElement.Create('PmtMtd', 'TRF'));
        PmtInfNode.Add(XmlElement.Create('NbOfTxs', '1'));
        PmtInfNode.Add(XmlElement.Create('CtrlSum', Format(Abs(GenJnlLine.Amount), 0, '<Precision,2:2><Standard Format,9>')));
        PmtInfNode.Add(XmlElement.Create('ReqdExctnDt', Format(GenJnlLine."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>')));
        PmtInfNode.Add(XmlElement.Create('Dbtr', XRTSetup."Company ID"));
        PmtInfNode.Add(XmlElement.Create('DbtrAcct', GenJnlLine."Bal. Account No."));
    end;

    local procedure AddCdtTrfTxInfNode(var CdtTrfTxInfNode: XmlElement; GenJnlLine: Record "Gen. Journal Line")
    begin
        CdtTrfTxInfNode.Add(XmlElement.Create('PmtId', Format(GenJnlLine."Line No.")));
        CdtTrfTxInfNode.Add(XmlElement.Create('Amt', Format(Abs(GenJnlLine.Amount), 0, '<Precision,2:2><Standard Format,9>')));
        CdtTrfTxInfNode.Add(XmlElement.Create('Cdtr', GenJnlLine."Account No."));
        CdtTrfTxInfNode.Add(XmlElement.Create('RmtInf', GenJnlLine.Description));
    end;

    local procedure BuildSwiftMT101(var GenJnlLine: Record "Gen. Journal Line"; XRTSetup: Record "XRT Setup"; var OutStream: OutStream): Integer
    var
        Content: Text;
        ExportCount: Integer;
        CRLF: Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        Content := ':20:' + CopyStr(GenJnlLine."Journal Batch Name", 1, 16) + CRLF;
        Content += ':28D:1/1' + CRLF;
        Content += ':50A:' + XRTSetup."Company ID" + CRLF;

        ExportCount := 0;
        if GenJnlLine.FindSet() then
            repeat
                Content += BuildSwiftTransaction(GenJnlLine, CRLF);
                ExportCount += 1;
            until GenJnlLine.Next() = 0;

        OutStream.WriteText(Content);
        exit(ExportCount);
    end;

    local procedure BuildSwiftTransaction(GenJnlLine: Record "Gen. Journal Line"; CRLF: Text[2]): Text
    var
        TxText: Text;
    begin
        TxText := ':21:' + CopyStr(Format(GenJnlLine."Line No."), 1, 16) + CRLF;
        TxText += ':32B:' + GenJnlLine."Currency Code" + Format(Abs(GenJnlLine.Amount), 0, '<Precision,2:2><Standard Format,9>') + CRLF;
        TxText += ':59:' + GenJnlLine."Account No." + CRLF;
        TxText += ':70:' + CopyStr(GenJnlLine.Description, 1, 35) + CRLF;
        exit(TxText);
    end;

    local procedure GetPaymentFileName(FileFormat: Enum "XRT Payment File Format"): Text
    var
        DateTimeStr: Text;
    begin
        DateTimeStr := Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>');
        case FileFormat of
            FileFormat::SEPA,
            FileFormat::"PAIN.001":
                exit('XRT_Payment_' + DateTimeStr + '.xml');
            FileFormat::"Swift MT101":
                exit('XRT_Payment_' + DateTimeStr + '.txt');
            FileFormat::"CFONB":
                exit('XRT_Payment_' + DateTimeStr + '.asc');
            FileFormat::"BACS":
                exit('XRT_Payment_' + DateTimeStr + '.bacs');
            FileFormat::"ACH":
                exit('XRT_Payment_' + DateTimeStr + '.ach');
            else
                exit('XRT_Payment_' + DateTimeStr + '.xml');
        end;
    end;

    local procedure CreatePaymentFileRecord(var XRTPaymentFile: Record "XRT Payment File"; var GenJnlLine: Record "Gen. Journal Line"; XRTSetup: Record "XRT Setup"; FileName: Text; ExportCount: Integer)
    var
        BankAccount: Record "Bank Account";
        TotalAmount: Decimal;
    begin
        TotalAmount := 0;
        if GenJnlLine.FindSet() then
            repeat
                TotalAmount += Abs(GenJnlLine.Amount);
            until GenJnlLine.Next() = 0;

        XRTPaymentFile.Init();
        XRTPaymentFile."File Name" := CopyStr(FileName, 1, MaxStrLen(XRTPaymentFile."File Name"));
        XRTPaymentFile."Creation Date" := Today();
        XRTPaymentFile."Creation Time" := Time();
        XRTPaymentFile."Created By" := CopyStr(UserId(), 1, MaxStrLen(XRTPaymentFile."Created By"));
        XRTPaymentFile."Bank Account No." := GenJnlLine."Bal. Account No.";
        if BankAccount.Get(GenJnlLine."Bal. Account No.") then
            XRTPaymentFile."Bank Account Name" := CopyStr(BankAccount.Name, 1, MaxStrLen(XRTPaymentFile."Bank Account Name"));
        XRTPaymentFile.Status := XRTPaymentFile.Status::New;
        XRTPaymentFile."File Format" := XRTSetup."Payment File Format";
        XRTPaymentFile."Total Amount" := TotalAmount;
        XRTPaymentFile."Currency Code" := GenJnlLine."Currency Code";
        XRTPaymentFile."No. of Payments" := ExportCount;
        XRTPaymentFile.Insert();
    end;

    local procedure DownloadPaymentFile(var TempBlob: Codeunit "Temp Blob"; FileName: Text)
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        DownloadFromStream(InStream, '', '', '', FileName);
    end;

    local procedure ImportStatementsFromAPI(XRTSetup: Record "XRT Setup"): Integer
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        RequestUrl: Text;
        ResponseText: Text;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        ImportCount: Integer;
    begin
        ImportCount := 0;
        if XRTSetup."Service URL" = '' then
            exit(ImportCount);

        RequestUrl := XRTSetup."Service URL" + '/statements/pending';

        SetAuthorizationHeader(HttpClient, XRTSetup);
        if not HttpClient.Get(RequestUrl, HttpResponse) then
            exit(ImportCount);

        if not HttpResponse.IsSuccessStatusCode() then
            exit(ImportCount);

        HttpResponse.Content().ReadAs(ResponseText);

        if not JsonArray.ReadFrom(ResponseText) then
            exit(ImportCount);

        foreach JsonToken in JsonArray do
            if ProcessStatementFromJson(JsonToken.AsObject()) then
                ImportCount += 1;

        exit(ImportCount);
    end;

    local procedure ProcessStatementFromJson(JsonObject: JsonObject): Boolean
    var
        XRTBankStatement: Record "XRT Bank Statement";
        JsonToken: JsonToken;
    begin
        XRTBankStatement.Init();
        XRTBankStatement."Import Date" := Today();
        XRTBankStatement."Import Time" := Time();
        XRTBankStatement."Imported By" := CopyStr(UserId(), 1, MaxStrLen(XRTBankStatement."Imported By"));
        XRTBankStatement.Status := XRTBankStatement.Status::Imported;

        if JsonObject.Get('bankAccountNo', JsonToken) then
            XRTBankStatement."Bank Account No." := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(XRTBankStatement."Bank Account No."));

        if JsonObject.Get('statementDate', JsonToken) then
            if not Evaluate(XRTBankStatement."Statement Date", JsonToken.AsValue().AsText()) then begin
                XRTBankStatement.Status := XRTBankStatement.Status::Error;
                XRTBankStatement."Error Message" := CopyStr(
                    StrSubstNo('Failed to parse statement date: %1', JsonToken.AsValue().AsText()),
                    1, MaxStrLen(XRTBankStatement."Error Message"));
            end;

        if JsonObject.Get('statementNo', JsonToken) then
            XRTBankStatement."Statement No." := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(XRTBankStatement."Statement No."));

        if JsonObject.Get('openingBalance', JsonToken) then
            XRTBankStatement."Opening Balance" := JsonToken.AsValue().AsDecimal();

        if JsonObject.Get('closingBalance', JsonToken) then
            XRTBankStatement."Closing Balance" := JsonToken.AsValue().AsDecimal();

        if JsonObject.Get('currency', JsonToken) then
            XRTBankStatement."Currency Code" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(XRTBankStatement."Currency Code"));

        if JsonObject.Get('noOfLines', JsonToken) then
            XRTBankStatement."No. of Lines" := JsonToken.AsValue().AsInteger();

        if JsonObject.Get('fileName', JsonToken) then
            XRTBankStatement."File Name" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(XRTBankStatement."File Name"));

        XRTBankStatement.Insert();
        exit(true);
    end;

    local procedure SetAuthorizationHeader(var HttpClient: HttpClient; XRTSetup: Record "XRT Setup")
    var
        XRTAuthHelper: Codeunit "XRT Auth Helper";
    begin
        XRTAuthHelper.SetAuthorizationHeader(HttpClient, XRTSetup);
    end;
}
