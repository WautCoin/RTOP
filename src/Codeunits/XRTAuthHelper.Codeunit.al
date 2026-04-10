codeunit 50102 "XRT Auth Helper"
{
    Caption = 'XRT Auth Helper';
    Access = Internal;

    var
        PasswordStorageKeyTok: Label 'XRT_PASSWORD', Locked = true;

    procedure SetPassword(Password: SecretText)
    begin
        IsolatedStorage.Set(PasswordStorageKeyTok, Password, DataScope::Module);
    end;

    procedure GetPassword(var Password: SecretText): Boolean
    begin
        exit(IsolatedStorage.Get(PasswordStorageKeyTok, DataScope::Module, Password));
    end;

    procedure HasPassword(): Boolean
    begin
        exit(IsolatedStorage.Contains(PasswordStorageKeyTok, DataScope::Module));
    end;

    procedure DeletePassword()
    begin
        if IsolatedStorage.Contains(PasswordStorageKeyTok, DataScope::Module) then
            IsolatedStorage.Delete(PasswordStorageKeyTok, DataScope::Module);
    end;

    procedure SetAuthorizationHeader(var HttpClient: HttpClient; XRTSetup: Record "XRT Setup")
    var
        Base64Convert: Codeunit "Base64 Convert";
        Password: SecretText;
        Credentials: SecretText;
        CredPrefix: Text;
    begin
        if XRTSetup."User Name" = '' then
            exit;
        if not GetPassword(Password) then
            exit;

        CredPrefix := XRTSetup."User Name" + ':';
        Credentials := SecretStrSubstNo('%1%2', CredPrefix, Password);
        HttpClient.DefaultRequestHeaders().Add('Authorization', SecretStrSubstNo('Basic %1', Base64Convert.ToBase64(Credentials)));
    end;
}
