import TrustKit

let trustKitConfig = [
    kTSKPinnedDomains: [
        baseDomain: [
            kTSKIncludeSubdomains: NSNumber(value: true),
            kTSKEnforcePinning: NSNumber(value: true),
            kTSKPublicKeyHashes: [
                "psmaXsNEQMAcQikTDZYnDYdZTi2FspxEiLcwxoKXtEA=",
                "SVDc8R/k6PEHYdk/xtajSqqlO7yosaFygdu9qQb/eD8=",
                "kJSrlTzuvigY9oNV5DB1qzJLxZFU+Z2DRtOv6ra6LZ0=",
                "HD887onXp9ZkSz8QfqOzodXiJcGGmyQRRUa5fsdE9R0="
            ]
        ],
        filesBaseDomain: [
            kTSKIncludeSubdomains: NSNumber(value: true),
            kTSKEnforcePinning: NSNumber(value: true),
            kTSKPublicKeyHashes: [
                "qHG2qARLCPHRKfr0clCZwqTau+wLVJgEsnHDk7owVXs=",
                "m4WHKUfFpnDiMlfU4udGkHVy9Z9svzHrlOjCd/wT2A4=",
                "520BPZE5dS/bczUq6aU+9AqSc1O0L1jbHVR/QBccVfU=",
                "kNlTopCOsrEv9buAm9nBbWe4FjEn/QDaewi747PyW/4="
            ]
        ]
    ]
]
