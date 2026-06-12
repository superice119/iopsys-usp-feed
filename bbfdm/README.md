# BBFDM configuration options and utilities

bbfdm provides few compile time configuration options and compile time help utility called [bbfdm.mk](./bbfdm.mk), this document aimed to explain the available usages and best practices.

## Compilation options

|  Configuration option    | Description   | Default Value |
| -----------------------  | ------------- | ----------- |
| CONFIG_BBF_VENDOR_LIST   | List of vendor extension directories | iopsys        |
| CONFIG_BBF_VENDOR_PREFIX | Prefix for Vendor extension datamodel objects/parameters | X_IOPSYS_EU_  |
| CONFIG_BBF_MAX_OBJECT_INSTANCES | Maximum number of instances per object | 255    |
| BBF_OBFUSCATION_KEY      | Hash used to encode/decode in `bbf.secure` object | 371d530c95a17d1ca223a29b7a6cdc97e1135c1e0959b51106cca91a0b148b5e42742d372a359760742803f2a44bd88fca67ccdcfaeed26d02ce3b6049cb1e04 |


#### BBF_OBFUSCATION_KEY

`bbfdm` provides an ubus object called `bbf.secure` to allow encoding/decoding the values, `bbf.secure` currently support following methods internally to encode/decode

  - Encode/Decode using a predefined SHA512 Hash key
  - Encode/Decode using a private/public RSA key pair

The `BBF_OBFUSCATION_KEY` compile time configuration option used to defined the SHA512 HASH, if this option is undefined, then it usages a default value as mention in the above table.

User must override this parameter with their own hash value, to generate a hash user can run below command and copy the hash value to this option.

ex: User wants to use 'Sup3rS3cur3Passw0rd' as passkey, then can get the SHA512 sum with

```bash
$ echo -n "Sup3rS3cur3Passw0rd" | sha512sum
371d530c95a17d1ca223a29b7a6cdc97e1135c1e0959b51106cca91a0b148b5e42742d372a359760742803f2a44bd88fca67ccdcfaeed26d02ce3b6049cb1e04  -
```

> Note: Additionally, user can install RSA private key in '/etc/bbfdm/certificates/private_key.pem' path, if private key is present `bbf.secure` shall use rsa private certificate for encrypt/decrypt function. In case of key not present in the pre-defined path, hash will be used for the same.

## Helper utility (bbfdm.mk)

bbfdm provides a helper utility [bbfdm.mk](./bbfdm.mk) to install datamodel plugins in bbfdm core or in microservice directory.

