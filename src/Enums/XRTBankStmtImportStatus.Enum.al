enum 50103 "XRT Bank Stmt. Import Status"
{
    Caption = 'XRT Bank Statement Import Status';
    Extensible = true;

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Imported)
    {
        Caption = 'Imported';
    }
    value(2; Posted)
    {
        Caption = 'Posted';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
}
