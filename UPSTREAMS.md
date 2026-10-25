# Upstream components and source compliance

| Component | Source / pin | License and distribution note |
|---|---|---|
| foo2zjs | https://github.com/OpenPrinting/foo2zjs, commit `80499ed5bf6caa2963ad337e37cfda78a80aab1e` | GPL; the exact source commit is archived in `dist/source-code/` during a native build. `COPYING` is included in the bundle. |
| Ghostscript | Homebrew `ghostscript` formula; version, source URL, checksum and source archive recorded at build time | Ghostscript is distributed under AGPL/commercial terms depending on version/edition. The exact source archive and formula are collected for corresponding-source compliance; license review is still required before distributing a binary package. |
| JBIG-KIT | Homebrew `jbigkit` formula | Source archive and checksum collected during build; review included license and any notices before release. |
| GNU sed | Homebrew `gnu-sed` formula | GPL; source archive and checksum collected during build. |
| GNU bc / dc | Homebrew `bc` formula | GPL; source archive and checksum collected during build. |
| dylibbundler | Homebrew `dylibbundler` formula | Source archive and checksum collected during build; review license before release. |
| HP LaserJet 1020 firmware | Not downloaded by this project | Proprietary; the user supplies a local copy. It is never committed or bundled. The setup helper accepts only the reviewed SHA-256. |

`build/build-bundle.sh` records installed formula versions and collects stable source archives plus checksums for the exact Homebrew formulas used by that build. This improves source availability but does not replace legal review of license obligations, formula patches, and binary redistribution terms. Do not publish a prebuilt release until the source archive set and notices have been reviewed.
