// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

contract SupplyChain {
	enum TypeCofee {
		ARABIC,
		ROBUSTA
	} //tipos de cafe al momento de cosechar
	enum ToasterType {
		NATURAL,
		TORREFACTO
	} //se agrega zucar al tostado en torrefacto
	enum Transport {
		AIR,
		LAND
	} //medio de transporte

	struct Harvester {
		//datos unicos
		uint256 idLotHarvester;
		address harvester;
		//datos extras
		string place;
		uint date; //= block.timestamp; poner fecha
		uint256 amount;
		TypeCofee typeCoffe;
	}

	struct Provider {
		//datos unicos { #Lote del Cosechador, Quien le paga al proveedor(cuenta cosechador),LoteProveedor
		uint256 idLotHarvester;
		uint256 idLotProvider;
		address harvester;
		address provider;
		//Datos extras
		string place;
		uint date; //= block.timestamp; poner fecha
		uint256 amount;
	}

	//---contratos de exportacion
	struct Bill {
		uint256 amount;
		uint price;
	}

	struct Export {
		//DATOS UNICOS
		uint256 idLotProvider;
		uint256 idLotExport;
		//quien hace dicha exportacion y su proveedor relacionado
		address provider;
		address export;
		//Datos extras
		string place;
		uint date; //= block.timestamp; poner fecha
		uint256 certificateId;
		Bill bill;
	}

	struct Import {
		uint256 idLotExport;
		uint256 idLotImport;
		address export;
		address Import;
		uint256 idAduana;
		Bill bill;
		string puertoEntrada;
		string puertoSalida;
		string ruta;
		uint256 certificateId;
	}

	struct Toaster {
		address toaster;
		address Import;
		ToasterType typeToast;
		uint dateToast;
		uint dateDistribute;
	}

	struct Distribute {
		address toaster;
		address distributor;
		uint256 lotId;
		Transport transportMethod;
		uint dateSend;
		uint dateExpiration;
	}

	struct Store {
		address distributor;
		address store;
		string nameStore;
		string nameProduct;
		uint256 price;
		uint dateExpire;
	}

	//HASHES DE AYUDA PARA OBTENER TODAS LAS ORDENES DE ACUERDO A LA CUENTA DE DEPOSITO
	mapping(address => Harvester[]) harvesters;
	mapping(address => Provider[]) providers;
	mapping(address => Export[]) exporters;
	mapping(address => Import[]) importers;
	mapping(address => Toaster[]) toasters;
	mapping(address => Distribute[]) distributors;
	mapping(address => Store[]) stores;

	//ARREGLOS PARA LAS ORDENES PPARA HACER EL TRACKING A PARTIR DE SU ID
	mapping(uint256 => Harvester) harvOrders;
	mapping(uint256 => Provider) provOrders;
	mapping(uint256 => Export) exportOrders;

	//eventos
	event Harvested(uint256 lotId, address harvester);
	event provided(uint256 lotId, address provider);
	event Processed(uint256 lotId, address processor);
	event Exported(uint256 lotId, address exporter);
	event Imported(uint256 lotId, address importer);
	event Roasted(uint256 lotId, address toaster);
	event Distributed(uint256 lotId, address distributor);
	event Sold(uint256 lotId, address store);

	//FUNCIONES DE APOYO
	function calculatePrice(uint256 amount) private pure returns (uint) {
		uint coffeePricePerUnit = 1 ether;
		return amount * coffeePricePerUnit;
	}

	//comparar strings en solidity
	function compareStrings(
		string memory a,
		string memory b
	) public pure returns (bool) {
		return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
	}

	//IDS PARA LOS LOTES UNICOS
	uint256 LotHarvest = 1;
	uint256 LotProvider = 1;
	uint256 LotExport = 1;
	uint256 LotImport = 1;
	uint256 LotToaster = 1;
	uint256 LotDistribute = 1;
	uint256 LotStore = 1;

	//---------------------------------------------------------------------------------------------------------------------

	//---------------------------------C O S E C H A D O R -----------------------------------------------------------------
	// Función para que un productor registre una cosecha de café
	function registerHarvest(
		address harvesterAccount,
		string memory place,
		uint256 amount,
		string memory typeCoffe
	) public payable {
		uint totalPrice = calculatePrice(amount);
		console.log("Precio Ether:", totalPrice);
		console.log("Cantidad de Ether Tengo:", msg.value);
		console.log("VALOR 1 ETHER:", 1 ether);
		uint date = block.timestamp;

		// Verificar que el cliente haya enviado suficiente ether
		require(msg.value >= amount, "Insufficient payment");

		if (compareStrings(typeCoffe, "ARABIC") == true) {
			// Registrar la cosecha
			Harvester memory newHarvest = Harvester(
				LotHarvest,
				harvesterAccount,
				place,
				date,
				amount,
				TypeCofee.ARABIC
			);

			uint dineroAntes = newHarvest.harvester.balance;
			console.log("DINERO ANTES PAGO:", dineroAntes);

			payable(newHarvest.harvester).transfer(msg.value); //pagarle al cosechador
			harvesters[harvesterAccount].push(newHarvest);

			uint dineroDespues = newHarvest.harvester.balance;
			console.log("DINERO DESPUES PAGO:", dineroDespues);

			//agregar orden
			harvOrders[LotHarvest] = newHarvest;
		} else {
			Harvester memory newHarvest = Harvester(
				LotHarvest,
				harvesterAccount,
				place,
				date,
				amount,
				TypeCofee.ROBUSTA
			);
			payable(newHarvest.harvester).transfer(msg.value); //pagarle al cosechador
			harvesters[msg.sender].push(newHarvest);

			//agregar la orden
			harvOrders[LotHarvest] = newHarvest;
		}

		emit Harvested(LotHarvest, harvesterAccount); //emitir el evento de compra al cosechador
		LotHarvest++;
	}

	// Función para que un usuario obtenga una orden por su idLote específica de un cosechador
	function getHarvesterOrder(
		uint256 idLot
	) public view returns (Harvester memory) {
		require(
			harvOrders[idLot].idLotHarvester != 0,
			"NO LOTS WITH THIS ID!!"
		);
		return harvOrders[idLot];
	}

	//funcion para traer todas las ordenes o lotes que ha hecho un cosechador en general
	function getHarvesterOrders(
		address harvester
	) public view returns (Harvester[] memory) {
		return harvesters[harvester];
	}

	//---------------------- P R O V E E D O R ----------------------------------------------------------------------
	//agregar proveedor
	//Se agrego el id del lote del cosechador para poder relacionar la caja de ese lote con este proveedor
	function addProvider(
		uint256 idLotHarv,
		address providerAccount,
		string memory place,
		uint256 amount
	) public payable {
		uint date = block.timestamp;
		uint256 harvLotAmount = harvOrders[idLotHarv].amount;

		require(
			harvLotAmount >= amount,
			"NOT ENOUGH COFFEE ON THE HARVESTER LOT!!"
		);
		require(
			msg.value >= amount,
			"Insufficient Funds to send to Provider!!"
		);

		Provider memory newProvider = Provider(
			idLotHarv,
			LotProvider,
			msg.sender,
			providerAccount,
			place,
			date,
			amount
		);

		harvOrders[idLotHarv].amount -= amount; //reducir cargamento del lote

		//Pagarle al Proveedor
		payable(newProvider.provider).transfer(msg.value); //pagarle al proveedor

		//agregar al map de las ordenes hechas por este proveedor
		providers[providerAccount].push(newProvider);

		//agregar la orden que tiene su id para tracking
		provOrders[LotProvider] = newProvider;

		LotProvider++;
		emit provided(LotProvider, providerAccount);
	}

	//pedir todas las ordenes que ha hecho el proveedor
	function getProviderOrdersByAddress(
		address providerAccount
	) public view returns (Provider[] memory) {
		return providers[providerAccount];
	}

	//pedir una orden o lote que ha hecho ese proveedor con su idLote y ver su informacion
	function getProviderOrder(
		uint256 id
	) public view returns (Provider memory) {
		return provOrders[id];
	}

	//------------------------------------ E X P O R T A C I O N ----------------------------------------------------------

	//Realizar lote de exportacion
	function exportLot(
		uint256 idLotProv,
		address exportAccount,
		string memory place,
		uint256 amount,
		uint256 certificate
	) public payable {
		uint256 provLotAmount = provOrders[idLotProv].amount;

		require(
			provLotAmount >= amount,
			"NOT ENOUGH COFFEE ON THE HARVESTER LOT!!"
		);
		require(
			msg.value >= amount,
			"Insufficient Funds to send to Provider!!"
		);

		uint date = block.timestamp;

		uint256 price = amount * 3; //despues cambiar esto a una forma de calcular

		Bill memory bill = Bill(amount, price);
		Export memory Lot = Export(
			idLotProv,
			LotExport,
			msg.sender,
			exportAccount,
			place,
			date,
			certificate,
			bill
		);

		provOrders[idLotProv].amount -= amount; //reducr cantidad del lote que tiene el proveedor

		//Pagarle al exportador
		payable(Lot.export).transfer(msg.value); //pagarle al exportador

		//agregar a los lotes  en total de este eportador que hace
		exporters[exportAccount].push(Lot);

		//agregar este lote de exportacion
		exportOrders[LotExport] = Lot;

		emit Exported(LotExport, exportAccount);
	}

	//Extraer todos los lotes de exportacion que ha hecho un exportador por su cuenta
	function getOrdersExport(
		address account
	) public view returns (Export[] memory) {
		return exporters[account];
	}

	//extraer una orden de Exportacion por su Id de Lote
	function getExportOrder(uint256 id) public view returns (Export memory) {
		return exportOrders[id];
	}

	//----------------------------- I M P O R T -------------------------------------------------------
}
