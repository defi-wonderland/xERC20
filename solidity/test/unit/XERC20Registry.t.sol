// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from '../../test/utils/DSTestFull.sol';
import {XERC20Registry, IXERC20Registry} from '../../contracts/XERC20Registry.sol';

abstract contract Base is DSTestFull {
  address internal _owner = vm.addr(101);
  address internal _user = vm.addr(102);

  XERC20Registry internal _xerc20Registry;

  event XERC20Registry_XERC20Added(address _xerc20, address _erc20, address _lockbox, string _version);
  event XERC20Registry_XERC20Removed(address _xerc20);
  event XERC20Registry_ERC20MappingUpdated(address _xerc20, address _erc20);

  function setUp() public virtual {
    vm.prank(_owner);
    _xerc20Registry = new XERC20Registry();
  }
}

contract UnitXERC20AddXERC20 is Base {
  function testAddXERC20(address _xerc20, address _erc20, address _lockbox, string memory _version) public {
    vm.assume(_xerc20 > address(102));
    vm.assume(_erc20 > address(102));
    vm.assume(_lockbox > address(102));

    vm.prank(_owner);
    _xerc20Registry.addXERC20(_xerc20, _erc20, _lockbox, _version);
    (address _erc20Saved, address _lockboxSaved, string memory _versionSaved, bool _existsSaved) =
      _xerc20Registry.xerc20Data(_xerc20);
    assertEq(_erc20Saved, _erc20);
    assertEq(_lockboxSaved, _lockbox);
    assertEq(_versionSaved, _version);
    assertTrue(_existsSaved);

    assertEq(_xerc20Registry.erc20ToXERC20(_erc20), _xerc20);
  }

  function testAddXERC20ZeroERC20(address _xerc20, address _lockbox, string memory _version) public {
    vm.assume(_xerc20 > address(102));
    vm.assume(_lockbox > address(102));

    address _erc20 = address(0);

    vm.prank(_owner);
    _xerc20Registry.addXERC20(_xerc20, _erc20, _lockbox, _version);
    (address _erc20Saved, address _lockboxSaved, string memory _versionSaved, bool _existsSaved) =
      _xerc20Registry.xerc20Data(_xerc20);
    assertEq(_erc20Saved, _erc20);
    assertEq(_lockboxSaved, _lockbox);
    assertEq(_versionSaved, _version);
    assertTrue(_existsSaved);

    assertEq(_xerc20Registry.erc20ToXERC20(_erc20), address(0));
  }

  function testAddXERC20EmitsEvent(address _xerc20, address _erc20, address _lockbox, string memory _version) public {
    vm.assume(_xerc20 > address(102));
    vm.assume(_erc20 > address(102));
    vm.assume(_lockbox > address(102));

    vm.expectEmit(true, true, true, true);
    emit XERC20Registry_XERC20Added(_xerc20, _erc20, _lockbox, _version);

    vm.prank(_owner);
    _xerc20Registry.addXERC20(_xerc20, _erc20, _lockbox, _version);
  }

  function testAddXERC20Overrides(address _xerc20, address _erc20, address _lockbox, string memory _version) public {
    string memory _versionNew = 'new version';

    vm.assume(_xerc20 > address(102));
    vm.assume(_erc20 > address(102));
    vm.assume(_lockbox > address(102));
    vm.assume(keccak256(bytes(_version)) != keccak256(bytes(_versionNew)));

    vm.prank(_owner);
    _xerc20Registry.addXERC20(_xerc20, _erc20, _lockbox, _version);

    address _erc20New = vm.addr(200);
    address _lockboxNew = vm.addr(201);

    vm.prank(_owner);
    _xerc20Registry.addXERC20(_xerc20, _erc20New, _lockboxNew, _versionNew);
    (address _erc20Saved, address _lockboxSaved, string memory _versionSaved, bool _existsSaved) =
      _xerc20Registry.xerc20Data(_xerc20);
    assertEq(_erc20Saved, _erc20New);
    assertEq(_lockboxSaved, _lockboxNew);
    assertEq(_versionSaved, _versionNew);
    assertTrue(_existsSaved);

    assertEq(_xerc20Registry.erc20ToXERC20(_erc20New), _xerc20);
  }
}

contract UnitXERC20RemoveXERC20 is Base {
  address public xerc20 = vm.addr(200);
  address public erc20 = vm.addr(201);
  address public lockbox = vm.addr(202);
  string public version = '1';

  function setUp() public override {
    super.setUp();
    vm.prank(_owner);
    _xerc20Registry.addXERC20(xerc20, erc20, lockbox, version);
  }

  function testRemoveXERC20() public {
    vm.prank(_owner);
    _xerc20Registry.removeXERC20(xerc20);
    (address _erc20Saved, address _lockboxSaved, string memory _versionSaved, bool _existsSaved) =
      _xerc20Registry.xerc20Data(xerc20);
    assertEq(_erc20Saved, address(0));
    assertEq(_lockboxSaved, address(0));
    assertEq(_versionSaved, '');
    assertFalse(_existsSaved);

    assertEq(_xerc20Registry.erc20ToXERC20(erc20), address(0));
  }

  function testRemoveXERC20EmitsEvents() public {
    vm.expectEmit(true, true, true, true);
    emit XERC20Registry_XERC20Removed(xerc20);
    emit XERC20Registry_ERC20MappingUpdated(address(0), erc20);

    vm.prank(_owner);
    _xerc20Registry.removeXERC20(xerc20);
  }

  function testRemoveXERC20RevertsIfXERC20DoesNotExist() public {
    vm.expectRevert(IXERC20Registry.XERC20Registry_InvalidAddress.selector);
    vm.prank(_owner);
    _xerc20Registry.removeXERC20(vm.addr(300));
  }
}

contract UnitXERC20UpdateXERC20ForERC20 is Base {
  address public xerc20 = vm.addr(200);
  address public erc20 = vm.addr(201);
  address public lockbox = vm.addr(202);
  string public version = '1';

  address public xerc20New = vm.addr(300);

  function setUp() public override {
    super.setUp();
    vm.prank(_owner);
    _xerc20Registry.addXERC20(xerc20, erc20, lockbox, version);

    vm.prank(_owner);
    _xerc20Registry.addXERC20(xerc20New, erc20, lockbox, version);
  }

  function testUpdateXERC20ForERC20() public {
    vm.prank(_owner);
    _xerc20Registry.updateXERC20forERC20(xerc20, erc20);
    assertEq(_xerc20Registry.erc20ToXERC20(erc20), xerc20);
  }

  function testUpdateXERC20ForERC20ZeroERC20() public {
    vm.expectRevert(IXERC20Registry.XERC20Registry_InvalidAddress.selector);
    vm.prank(_owner);
    _xerc20Registry.updateXERC20forERC20(xerc20New, address(0));
  }

  function testUpdateXERC20ForERC20ERC20DoesNotMatch() public {
    address _xerc20New = vm.addr(500);
    vm.prank(_owner);
    _xerc20Registry.addXERC20(_xerc20New, vm.addr(400), lockbox, version);

    vm.expectRevert(IXERC20Registry.XERC20Registry_InvalidAddress.selector);
    vm.prank(_owner);
    _xerc20Registry.updateXERC20forERC20(_xerc20New, erc20);
  }

  function testUpdateXERC20ForERC20EmitsEvent() public {
    vm.expectEmit(true, true, true, true);
    emit XERC20Registry_ERC20MappingUpdated(xerc20, erc20);

    vm.prank(_owner);
    _xerc20Registry.updateXERC20forERC20(xerc20, erc20);
  }

  function testUpdateXERC20ForERC20RemovesOldXERC20() public {
    vm.prank(_owner);
    _xerc20Registry.updateXERC20forERC20(xerc20, erc20);
    (address _erc20Saved, address _lockboxSaved, string memory _versionSaved, bool _existsSaved) =
      _xerc20Registry.xerc20Data(xerc20New);
    assertEq(_erc20Saved, address(0));
    assertEq(_lockboxSaved, address(0));
    assertEq(_versionSaved, '');
    assertFalse(_existsSaved);
  }

  function testUpdateXERC20ForERC20RemovesOldXERC20EmitsEvent() public {
    vm.expectEmit(true, true, true, true);
    emit XERC20Registry_XERC20Removed(xerc20New);

    vm.prank(_owner);
    _xerc20Registry.updateXERC20forERC20(xerc20, erc20);
  }
}
