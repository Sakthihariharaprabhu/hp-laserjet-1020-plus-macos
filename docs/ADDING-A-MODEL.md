# Adding another printer model

Printer-specific facts live in one file per model in `models/`. Today there is one: `models/hp1020.conf`.

## What a model file holds

| Key | Meaning |
|---|---|
| `MODEL_ID` | Short lowercase id, for example `hp1020` |
| `MODEL_NAME` | Name shown to people |
| `USB_MATCH` | Regular expression that matches the printer in the CUPS USB listing |
| `FIRMWARE_FILE` | File name of the firmware |
| `FIRMWARE_SHA256` | The only accepted SHA-256 of that file |
| `FIRMWARE_URL` | `https://` address of the release asset |

`src/model-get` reads one key at a time and validates it. The file is never run as shell code.

## Steps for a new model

1. Copy `models/hp1020.conf` to `models/<id>.conf` and fill in the values.
2. Publish the firmware as a separate release asset. Never commit firmware to git or put it in the `.pkg`.
3. Add a PPD and the right `foo2zjs` arguments for the model (see `src/cups-filter` and `src/hp1020-clip`). Different families need different filter arguments, so expect real work here.
4. Extend `scripts/test-source.sh` with the model's checksum check.
5. Test with the real printer. Do not call a model supported before that.

## Honest status

Only the HP LaserJet 1020 / 1020 Plus is implemented. The filter, installer and app still assume one model at a time (`DRIVER_ID="hp1020"`). The model file removes the duplicated firmware data; choosing between several models at install time is future work.
