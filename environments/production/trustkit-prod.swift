import TrustKit

let trustKitConfig: [String: Any] = [
    kTSKPinnedDomains: [
        baseDomain: [
            kTSKIncludeSubdomains: NSNumber(value: true),
            kTSKEnforcePinning: NSNumber(value: true),
            kTSKPublicKeyHashes: [
                "AD1268BbF/w+Hh5JXyPLDLVAdh67VIG2agjkdYjC/kI=",
                "KhxI+AM5BFntDid1jc3tGAWOh/Qg8uG4ARPFF/QdXyg=",
                "3LJ/K6jSPOrKBxIZSUFxI0dmVpKPGj0a5WVm7/RPh8w=",
                "Mr5krFQTCZzw9aBSWDcRTiX6pD3qEpBytrjXwKt7/v8="
            ]
        ],
        filesBaseDomain: [
            kTSKIncludeSubdomains: NSNumber(value: true),
            kTSKEnforcePinning: NSNumber(value: true),
            kTSKPublicKeyHashes: [
                "u4OJJH+SZhvigfdKR+e1F3/OmICvFTnUl5Fnv6myaHg=",
                "OMEJX6dz1nbHkHom4UjDI6IV7MntvN2OyaV4xHsdRdA=",
                "dgbAjpXEfPJsPkFbQx99pUUg7iXQgCsjSNTs1A/X8mI=",
                "gVxo9q/ofaPErOFjlBfYGUlX4RPMYwFIcpCPKMWX3aM="
            ]
        ]
    ],
    kTSKDisableDefaultReportUri: true
]
