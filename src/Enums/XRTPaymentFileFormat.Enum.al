enum 50100 "XRT Payment File Format"
{
    Caption = 'XRT Payment File Format';
    Extensible = true;

    value(0; SEPA)
    {
        Caption = 'SEPA';
    }
    value(1; "PAIN.001")
    {
        Caption = 'PAIN.001';
    }
    value(2; "CFONB")
    {
        Caption = 'CFONB';
    }
    value(3; "Swift MT101")
    {
        Caption = 'Swift MT101';
    }
    value(4; "BACS")
    {
        Caption = 'BACS';
    }
    value(5; "ACH")
    {
        Caption = 'ACH';
    }
}
