enum 50101 "XRT Payment File Status"
{
    Caption = 'XRT Payment File Status';
    Extensible = true;

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Sent)
    {
        Caption = 'Sent';
    }
    value(2; Acknowledged)
    {
        Caption = 'Acknowledged';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
    value(4; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
