// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CBToken
 * @notice Token de gobernanza del protocolo CryptoBank
 * @dev Implementa ERC20 estándar con extensiones de votación (ERC20Votes)
 *      y permisos sin gas (ERC20Permit) para permitir delegación de voto
 *      y signatures off-chain.
 *
 * @dev FLUJO DE FUNCIONAMIENTO:
 *      1. El deployer recibe el total supply (100M tokens)
 *      2. Los holders pueden delegar su voto a direcciones
 *      3. Los delegados votan propuestas en el Governor
 *      4. ERC20Permit permite approvals sin transacciones on-chain
 *
 * @dev HERENCIA:
 *      ERC20 → Token estándar con transferencias y balances
 *      ERC20Permit → Firmas EIP-2612 para approvals sin gas
 *      ERC20Votes → Sistema de checkpoints para votación
 *      Ownable → Control de acceso al deployer inicial
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CBToken is ERC20, ERC20Permit, ERC20Votes, Ownable {

    // ========================================================================
    //                           CONSTANTES
    // ========================================================================

    /**
     * @notice Suministro máximo total de tokens
     * @dev 100,000,000 tokens con 18 decimales = 100_000_000 * 1e18
     *      Esta constante define el límite máximo que nunca se puede exceder
     */
    uint256 public constant MAX_SUPPLY = 100_000_000 * 1e18;

    // ========================================================================
    //                         CONSTRUCTOR
    // ========================================================================

    /**
     * @notice Constructor del token CB
     * @dev Inicializa el token con nombre, símbolo y minta todo el supply
     *      al deployer (msg.sender)
     *
     * @dev PARÁMETROS ERC20:
     *      - Nombre: "CryptoBank Token"
     *      - Símbolo: "CB"
     *
     * @dev PARÁMETROS ERC20Permit:
     *      - Nombre para dominio EIP-2612: "CryptoBank Token"
     *
     * @dev PASOS:
     *      1. Inicializa ERC20 con nombre y símbolo
     *      2. Inicializa ERC20Permit con nombre para dominio de firmas
     *      3. Inicializa Ownable con msg.sender como propietario
     *      4. Minta MAX_SUPPLY al deployer
     */
    constructor() ERC20("CryptoBank Token", "CB") ERC20Permit("CryptoBank Token") Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
    }

    // ========================================================================
    //                      FUNCIONES DE GOBERNANZA
    // ========================================================================

    /**
     * @notice Permite al propietario acuñar nuevos tokens
     * @dev Solo el owner puede llamar esta función
     *      Verifica que el total supply no exceda MAX_SUPPLY
     *
     * @param to Dirección receptor de los tokens
     * @param amount Cantidad de tokens a acuñar (en wei)
     *
     * @dev PASOS:
     *      1. Verifica que msg.sender es el owner (onlyOwner)
     *      2. Verifica que totalSupply + amount <= MAX_SUPPLY
     *      3. Minta los tokens a la dirección 'to'
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "CBToken: exceeds max supply");
        _mint(to, amount);
    }

    /**
     * @notice Permite quemar tokens de una dirección
     * @dev Cualquier holder puede quemar sus propios tokens
     *      Reduce el supply total permanentemente
     *
     * @param from Dirección de la que se quemarán los tokens
     * @param amount Cantidad de tokens a quemar (en wei)
     *
     * @dev PASOS:
     *      1. Verifica que 'from' tenga suficiente balance
     *      2. Reduce el balance de 'from'
     *      3. Reduce el total supply
     *      4. Emite evento Transfer con dirección zero
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    // ========================================================================
    //                     FUNCIONES INTERNAS (OVERRIDES)
    // ========================================================================

    /**
     * @notice Override interno para actualizar balances y checkpoints de voto
     * @dev Se ejecuta en cada transferencia, mint y burn
     *      Registra checkpoints para el sistema de votación
     *
     * @param from Dirección origen (address(0) en mint)
     * @param to Dirección destino (address(0) en burn)
     * @param value Cantidad transferida
     *
     * @dev FLUJO:
     *      1. ERC20._update() actualiza balances
     *      2. ERC20Votes._update() registra checkpoint de voto
     *      3. Si from es zero → es un mint
     *      4. Si to es zero → es un burn
     *      5. Si ambos existen → es una transferencia
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    /**
     * @notice Override para Nonces de ERC20Permit
     * @dev Previene replay de firmas EIP-2612
     *      Cada dirección tiene un nonce incrementable
     *
     * @param owner Dirección cuyo nonce se consulta
     * @return Nonce actual para esa dirección
     *
     * @dev USO:
     *      1. Frontend obtiene nonce actual
     *      2. Usuario firma mensaje con nonce
     *      3. Smart contract verifica nonce
     *      4. Nonce se incrementa tras uso exitoso
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
