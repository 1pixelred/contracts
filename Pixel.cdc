// Pixel.cdc
//
pub contract Pixel {

    pub let domains: [String]
    pub var domainId: UInt256

    pub let DomainStoragePath: StoragePath
    pub let DomainPublicPath: PublicPath

    pub let PortfolioStoragePath: StoragePath
    pub let PortfolioPublicPath: PublicPath

   pub resource DomainNFT {
        pub let id: UInt256
        pub let url: String
        pub var metadata: {String: String}
        init(_ id: UInt256, _ url: String) {
            self.id = id
            self.url = url
            self.metadata = {}
        }
    }

    pub resource interface IPortfolio {
        pub fun insert(_ token: @DomainNFT)
        pub fun getDomains(): [String]
        pub fun domainExists(_ domain: String): Bool
    }

    pub resource Portfolio: IPortfolio {
        pub var ownedDomains: @{String: DomainNFT}

        init () {
            self.ownedDomains <- {}
        }

        pub fun remove(_ domain: String): @DomainNFT {
            let token: @DomainNFT <- self.ownedDomains.remove(key: domain)
                ?? panic("Cannot remove the specified domain NFT")
            return <-token
        }

        pub fun insert(_ token: @DomainNFT) {
            self.ownedDomains[token.url] <-! token
        }

        pub fun domainExists(_ domain: String): Bool {
            return self.ownedDomains[domain] != nil
        }

        pub fun getDomains(): [String] {
            return self.ownedDomains.keys
        }

        destroy() {
            destroy self.ownedDomains
        }
    }

    pub fun createEmptyPortfolio(): @Portfolio {
        return <- create Portfolio()
    }

    init() {
        self.DomainStoragePath = /storage/nftStorageDomain
        self.DomainPublicPath = /public/nftPublicDomain

        self.PortfolioStoragePath = /storage/nftStoragePortfolio
        self.PortfolioPublicPath = /public/nftPublicPortfolio

        self.domains = []
        self.domainId = 0

        self.account.save(<-self.createEmptyPortfolio(), to: self.PortfolioStoragePath)
        self.account.link<&{IPortfolio}>(self.PortfolioPublicPath, target: self.PortfolioStoragePath)
    }

    pub fun addDomain(_ hexDomain: String) {
        self.domains.append(hexDomain)
    }

    pub fun getDomains(): [String] {
        return self.domains
    }

    pub fun hexDomain(_ domain: String): String {
        let domainArr: [UInt8] = HashAlgorithm.SHA3_256.hash(domain.utf8)
        let domainHash: String = String.encodeHex(domainArr)
        return domainHash
    }

    pub fun winDomain(_ domain: String): @DomainNFT? {
        let hex: String = self.hexDomain(domain)

        if self.domains.contains(hex) {
            let index: Int = self.domains.firstIndex(of: hex) ?? -1
            self.domains.remove(at: index)
            self.domainId = self.domainId + 1
            return <-create DomainNFT(self.domainId, "#".concat(self.domainId.toString()).concat(" ").concat(domain))
        }

        return nil
    }
}
 