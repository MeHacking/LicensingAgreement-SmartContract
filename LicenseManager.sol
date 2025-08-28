// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LicenseManager {
    address public provider;
    uint256 public price;

    struct License {
        uint256 expiresAt;
        string code;
        bool active;
    }

    mapping(address => License) private licenses;
    address[] private clients;

    constructor(uint _price) {
        price = _price;
        provider = msg.sender;
    }

    modifier onlyProvider() {
        require(msg.sender == provider, "Only provider can perform this action");
        _;
    }

    modifier onlyClient() {
        require(msg.sender != provider, "Only clients can perform this action");
        _;
    }

    // Kupovina licence
    function buyLicense() external payable onlyClient {
        require(msg.value == price, "Wrong price");
        License storage L = licenses[msg.sender];
        require(!L.active || block.timestamp >= L.expiresAt, "Already active");

        L.expiresAt = block.timestamp + 30 days;
        L.code = generateCode(msg.sender);
        L.active = true;
        clients.push(msg.sender);
    }

    // Obnova licence
    function renewLicense() external payable onlyClient {
        require(msg.value == price, "Wrong price");
        License storage L = licenses[msg.sender];
        require(L.active, "No active license");
        require(block.timestamp >= L.expiresAt - 5 days, "Too early to renew");
        require(block.timestamp < L.expiresAt, "Expired already");

        L.expiresAt = L.expiresAt + 30 days;
    }

    // Uvid klijenta u svoju licencu
    function getMyCode() external view onlyClient returns (string memory) {
        License memory L = licenses[msg.sender];
        require(L.active && block.timestamp < L.expiresAt, "Not active");
        return L.code;
    }

    // Uvid Providera u licencu klijenta
    function getClientCode(address client) external view onlyProvider returns (string memory) {
        License memory L = licenses[client];
        require(L.active && block.timestamp < L.expiresAt, "Not active");
        return L.code;
    }

    //Uvid Providera u listu klijenata
    function getClients() external view onlyProvider returns (address[] memory) {
        return clients;
    }

    // Provera validnosti licence
    function isLicensed(address client) external view returns (bool) {
        License memory L = licenses[client];
        return L.active && block.timestamp < L.expiresAt;
    }

    // Podizanje ETH od strane providera
    function withdraw() external onlyProvider {
        payable(provider).transfer(address(this).balance);
    }

    // Uklanjanje klijenata iz liste aktivnih
    function removeClient(address client) external onlyProvider {
        require(licenses[client].active, "Client not found");
        licenses[client].active = false;
    }

    // Generisanje licence
    function generateCode(address user) internal view returns (string memory) {
        bytes memory characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        bytes memory generatedLicence = new bytes(10);

        bytes32 random = keccak256(
            abi.encodePacked(block.timestamp, user, address(this))
        );

        for (uint256 i = 0; i < 10; i++) {
            generatedLicence[i] = characters[uint8(random[i]) % characters.length];
        }
        return string(generatedLicence);
    }
}
