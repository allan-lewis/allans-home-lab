# Reference Models

Third-party models used for measurement only. Model files are gitignored; download them from the source to compare locally.

| Model | Source | Designer | License |
| --- | --- | --- | --- |
| 10-Inch 1U 12-Port CAT6 Keystone Patch Panel (`10in_1U_12P_CAT6_Keystone_Panel.3mf`) | MakerWorld | Shubham Patel | MakerWorld Exclusive (no redistribution) |
| USW-Flex-2.5G-8-PoE 10-inch Rack Mount (`USW-Flex-2.5G-8-PoE+10i+RM.3mf`) | [MakerWorld](https://makerworld.com/en/models/1024496) | Mauker | CC BY-NC-SA |
| ZimaBoard 2 (`20250905-icewhale-zimaboard2.glb`) | [Zima 3D models](https://shop.zimaspace.com/pages/zima-3d-models-home-server-nas) | IceWhale | Official download; no license stated |

The keystone panel is known to fit the DeskPi RackMate T2 and the keystone jacks in use. Panel dimensions in `hardware/lib/rack10.scad` are measured from it.

The USW-Flex mount was used only to confirm the switch's outline and the clearance needed around it. `rack-10in/mount-usw-flex-2.5g-8-poe.scad` is an independent rear-loading design.

The ZimaBoard 2 model is in meters. `rack-10in/shelf-zimaboard-2.scad` takes its outline, port heights and PCIe slot position from it.
