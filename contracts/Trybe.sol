// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

contract MyToken is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Strings for uint256;

    mapping(uint256 => Word) private wordsToTokenId;
    uint private fee = 0.005 ether;

    struct Word {
        string text;
        uint256 bgHue;
        uint256 textHue;
    }

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function randomHue(uint8 _salt) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.number,
                        false,
                        totalSupply(),
                        false,
                        _salt
                    )
                )
            ) % 361;
    }

    function mint(
        string memory _userText,
        address _destination
    ) public payable {
        require(bytes(_userText).length <= 30, "Text is too long");
        uint256 newSupply = totalSupply() + 1;

        Word memory newWord = Word(_userText, randomHue(1), randomHue(2));

        if (msg.sender != owner()) {
            require(
                msg.value >= fee,
                string(
                    abi.encodePacked("Missing fee of ", fee.toString(), " wei")
                )
            );
        }

        wordsToTokenId[newSupply] = newWord;
        _mint(_destination, newSupply, 1, "");
    }

    function mint(string memory _userText) public payable {
        mint(_userText, msg.sender);
    }

    function buildImage(
        string memory _userText,
        uint256 _bgHue,
        uint256 _textHue
    ) private pure returns (bytes memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg">'
                    '<rect height="100%" width="100%" y="0" x="0" fill="hsl(',
                    _bgHue.toString(),
                    ',50%,25%)"/>'
                    '<text y="50%" x="50%" text-anchor="middle" dy=".3em" fill="hsl(',
                    _textHue.toString(),
                    ',100%,80%)">',
                    _userText,
                    "</text>"
                    "</svg>"
                )
            );
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
