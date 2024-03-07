// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Tracking {
	enum RamStatus {
		ENSAMBLADO,
		PROGRAMADO,
		PROBADO,
		EMPACADO,
		ENVIADO,
		COMPLETO
	}

	struct Ram {
		address sender;
		address receptor;
		uint256 fechaCreacion;
		uint256 fechaEnvio;
		uint256 tipo;
		uint256 cantidad;
		RamStatus status;
		bool isPaid;
	}

	mapping(address => Ram[]) public rams;
	uint256 public ramCount;

	struct TypeRam {
		address sender;
		address receptor;
		uint256 fechaCreacion;
		uint256 fechaEnvio;
		uint256 tipo;
		uint256 cantidad;
		RamStatus status;
		bool isPaid;
	}

	TypeRam[] typeRams;

	event RamEnviada(
		address indexed sender,
		address indexed receptor,
		uint256 fechaCreacion
	);

	event RamAssembled(
		address indexed sender,
		address indexed receptor,
		uint256 fechaCreacion,
		uint256 tipo,
		uint256 cantidad
	);
	event RamProgrammed(address indexed sender, address indexed receptor);
	event RamTested(address indexed sender, address indexed receptor);
	event RamPacked(address indexed sender, address indexed receptor);
	event RamDelivered(
		address indexed sender,
		address indexed receptor,
		uint256 fechaEnvio
	);
	event RamPaid(
		address indexed sender,
		address indexed receptor,
		uint256 amount
	);

	constructor() {
		ramCount = 0;
	}

	function createRam(
		address _receptor,
		uint256 _fechaCreacion,
		uint256 _tipo,
		uint256 _cantidad
	) public payable {
		require(
			msg.value == _cantidad,
			"El monto del pago debe coincidir con el cantidad."
		);

		Ram memory ram = Ram(
			msg.sender,
			_receptor,
			_fechaCreacion,
			0,
			_tipo,
			_cantidad,
			RamStatus.ENSAMBLADO,
			false
		);

		rams[msg.sender].push(ram);
		ramCount++;

		typeRams.push(
			TypeRam(
				msg.sender,
				_receptor,
				_fechaCreacion,
				0,
				_tipo,
				_cantidad,
				RamStatus.ENSAMBLADO,
				false
			)
		);

		emit RamAssembled(
			msg.sender,
			_receptor,
			_fechaCreacion,
			_tipo,
			_cantidad
		);
	}

	function programmedRam(
		address _sender,
		address _receptor,
		uint256 _index
	) public {
		Ram storage ram = rams[_sender][_index];
		TypeRam storage typeRam = typeRams[_index];

		require(ram.receptor == _receptor, "Receptor inexistente.");
		require(ram.status == RamStatus.ENSAMBLADO, "RAM PROGRAMADA.");

		ram.status = RamStatus.PROGRAMADO;
		typeRam.status = RamStatus.PROGRAMADO;

		emit RamProgrammed(_sender, _receptor);
	}

	function testRam(
		address _sender,
		address _receptor,
		uint256 _index
	) public {
		Ram storage ram = rams[_sender][_index];
		TypeRam storage typeRam = typeRams[_index];

		require(ram.receptor == _receptor, "Receptor inexistente.");
		require(ram.status == RamStatus.PROGRAMADO, "RAM PROGRAMADA.");

		ram.status = RamStatus.PROBADO;
		typeRam.status = RamStatus.PROBADO;

		emit RamTested(_sender, _receptor);
	}

	function packedRam(
		address _sender,
		address _receptor,
		uint256 _index
	) public {
		Ram storage ram = rams[_sender][_index];
		TypeRam storage typeRam = typeRams[_index];

		require(ram.receptor == _receptor, "Receptor inexistente.");
		require(ram.status == RamStatus.PROBADO, "RAM PROGRAMADA.");

		ram.status = RamStatus.EMPACADO;
		typeRam.status = RamStatus.EMPACADO;

		emit RamPacked(_sender, _receptor);
	}

	function startRam(
		address _sender,
		address _receptor,
		uint256 _index
	) public {
		Ram storage ram = rams[_sender][_index];
		TypeRam storage typeRam = typeRams[_index];

		require(ram.receptor == _receptor, "Receptor inexistente.");
		require(ram.status == RamStatus.EMPACADO, "RAM enviada.");

		ram.status = RamStatus.ENVIADO;
		typeRam.status = RamStatus.ENVIADO;

		emit RamEnviada(_sender, _receptor, ram.fechaCreacion);
	}

	function completeRam(
		address _sender,
		address _receptor,
		uint256 _index
	) public {
		Ram storage ram = rams[_sender][_index];
		TypeRam storage typeRam = typeRams[_index];

		require(ram.receptor == _receptor, "Receptor inexistente.");
		require(ram.status == RamStatus.ENVIADO, "ram not in transit.");
		require(!ram.isPaid, "Ram proceso completado.");

		ram.status = RamStatus.COMPLETO;
		typeRam.status = RamStatus.COMPLETO;
		typeRam.fechaEnvio = block.timestamp;
		ram.fechaEnvio = block.timestamp;

		uint256 amount = ram.cantidad;

		payable(ram.sender).transfer(amount);

		ram.isPaid = true;
		typeRam.isPaid = true;

		emit RamDelivered(_sender, _receptor, ram.fechaEnvio);
		emit RamPaid(_sender, _receptor, amount);
	}

	function getRam(
		address _sender,
		uint256 _index
	)
		public
		view
		returns (
			address,
			address,
			uint256,
			uint256,
			uint256,
			uint256,
			RamStatus,
			bool
		)
	{
		Ram memory ram = rams[_sender][_index];
		return (
			ram.sender,
			ram.receptor,
			ram.fechaCreacion,
			ram.fechaEnvio,
			ram.tipo,
			ram.cantidad,
			ram.status,
			ram.isPaid
		);
	}

	function getRamsCount(address _sender) public view returns (uint256) {
		return rams[_sender].length;
	}

	function getAllTransactions() public view returns (TypeRam[] memory) {
		return typeRams;
	}
}
