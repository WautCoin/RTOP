# RTOP — XRT Treasury Integration for Business Central

A Microsoft Dynamics 365 Business Central AL extension that integrates Business Central with the **XRT treasury and cash management solution** (Sage Group).

## Features

- **Payment Export** — Generate payment files in SEPA/PAIN.001, Swift MT101, CFONB, BACS, and ACH formats and send them to XRT for processing.
- **Bank Statement Import** — Retrieve bank statement files from XRT in CAMT.053, CFONB120, Swift MT940, OFX, and BAI2 formats.
- **Status Tracking** — Monitor payment file status (New → Sent → Acknowledged / Rejected / Cancelled) with real-time refresh from the XRT API.
- **Secure Connectivity** — HTTP Basic Authentication against the XRT web service.

## Setup

1. Open the **XRT Setup** page (search for *XRT Setup* in Business Central).
2. Enable the integration and fill in the **Service URL**, **Company ID**, **User Name**, and **Password**.
3. Configure the **Export Path** and **Import Path** folders used for file exchange.
4. Choose the default **Payment File Format** and **Bank Statement Format**.
5. Use the **Test Connection** action to verify connectivity.

## Objects

| Object Type | ID    | Name                  |
|-------------|-------|-----------------------|
| Table       | 50100 | XRT Setup             |
| Table       | 50101 | XRT Payment File      |
| Table       | 50102 | XRT Bank Statement    |
| Page        | 50100 | XRT Setup Card        |
| Page        | 50101 | XRT Payment Files     |
| Page        | 50102 | XRT Bank Statements   |
| Codeunit    | 50100 | XRT Management        |
| Codeunit    | 50101 | XRT File Export       |
| Codeunit    | 50102 | XRT Auth Helper       |
| Enum        | 50100 | XRT Payment File Format |
| Enum        | 50101 | XRT Payment File Status |
| Enum        | 50102 | XRT Bank Stmt. Format |
| Enum        | 50103 | XRT Bank Stmt. Import Status |

## Requirements

- Business Central 2024 Wave 1 (Application version 24.0+)
- Access to an XRT treasury management environment

## License

BSD 2-Clause — see [LICENSE](LICENSE).
