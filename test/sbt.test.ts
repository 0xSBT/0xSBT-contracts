import { ValidationsCacheOutdated } from "@openzeppelin/hardhat-upgrades/dist/utils";
import { expect } from "chai";
import { ethers, waffle, web3 } from "hardhat";
import * as sbt from "../artifacts/contracts/SoulBoundToken/BoilerPlateSBT.sol/SoulBoundToken.json";

const { loadFixture, deployContract } = waffle;

type UnPromisify<T> = T extends Promise<infer U> ? U : T;

describe("SoulBoundToken", function () {
  async function buildFixture() {
    const accounts = await ethers.getSigners();
    const [alice, bob, charlie, dave, eve] = accounts;
    const owner = alice;

    const SBT = await deployContract(owner, sbt, ["test SBT", "test"]);

    return {
      accounts,
      alice,
      bob,
      charlie,
      SBT,
    };
  }
  let fixture: UnPromisify<ReturnType<typeof buildFixture>>;
  beforeEach(async function () {
    fixture = await loadFixture(buildFixture);
  });

  describe("mint sbt", function () {
    it("should mint sbt", async function () {
      const { alice, bob, charlie, SBT } = fixture;
      expect(await SBT.safeMintWithTokenURI(alice.address, "test1")).to.emit(SBT, "Transfer");
      expect(await SBT.safeMintWithTokenURI(bob.address, "test2")).to.emit(SBT, "Transfer");
    });
  });

  describe("burn sbt", function () {
    it("should burn sbt", async function () {
      const { alice, bob, charlie, SBT } = fixture;
      expect(await SBT.safeMintWithTokenURI(alice.address, "test1")).to.emit(SBT, "Transfer");
      expect(await SBT.burn(0)).to.emit(SBT, "Transfer");
    });
  });

  describe("Voting test", function () {
    beforeEach(async () => {
      const { alice, bob, charlie, SBT } = fixture;
      expect(await SBT.safeMintWithTokenURI(alice.address, "test1")).to.emit(SBT, "Transfer");
      expect(await SBT.safeMintWithTokenURI(bob.address, "test2")).to.emit(SBT, "Transfer");
      expect(await SBT.safeMintWithTokenURI(charlie.address, "test1")).to.emit(SBT, "Transfer");

      await SBT.connect(alice).manageDao(alice.address, true);
    });

    it("vote for alice dao", async function () {
      const { alice, bob, charlie, SBT } = fixture;
      await SBT.connect(alice).vote(alice.address, [9, 10, 7]);
      await SBT.connect(bob).vote(alice.address, [8, 9, 6]);
      await SBT.connect(charlie).vote(alice.address, [7, 8, 5]);

      console.log(await SBT.viewScore(alice.address));
    });

    it("vote cancel should work", async function () {
      const { alice, bob, charlie, SBT } = fixture;
      await SBT.connect(alice).vote(alice.address, [10, 10, 10]);
      await SBT.connect(bob).vote(alice.address, [10, 10, 10]);
      await SBT.connect(charlie).vote(alice.address, [5, 5, 5]);

      console.log(await SBT.viewScore(alice.address));

      await SBT.connect(alice).burn(2);

      console.log(await SBT.viewScore(alice.address));
    });
  });
});
