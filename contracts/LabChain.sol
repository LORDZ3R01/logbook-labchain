// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LabChain {
    address public immutable admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Hanya admin");
        _;
    }

    struct Alat {
        string nama;
        uint256 totalStok;
        uint256 sedangDipinjam;
        bool aktif;
    }

    enum Status {
        MenungguPersetujuan,
        Disetujui,
        Ditolak,
        MenungguPengembalian,
        Dikembalikan
    }

    struct Peminjaman {
        uint256 alatId;
        uint256 jumlah;
        address peminjam;
        uint256 waktuPengajuan;
        uint256 waktuPersetujuan;
        uint256 waktuPengajuanKembali;
        uint256 waktuPengembalian;
        Status status;
    }

    Alat[] private daftarAlat;
    Peminjaman[] private daftarPeminjaman;

    event AlatDitambahkan(uint256 indexed id, string nama);
    event PeminjamanDiajukan(
        uint256 indexed id,
        uint256 indexed alatId,
        address indexed peminjam
    );
    event PeminjamanDisetujui(uint256 indexed id);
    event PeminjamanDitolak(uint256 indexed id);
    event PengembalianDiajukan(uint256 indexed id);
    event PengembalianDikonfirmasi(uint256 indexed id);

    function tambahAlat(
        string memory nama,
        uint256 totalStok
    ) public onlyAdmin {
        require(bytes(nama).length > 0, "Nama alat kosong");
        require(totalStok > 0, "Stok harus lebih dari nol");

        daftarAlat.push(
            Alat(nama, totalStok, 0, true)
        );

        emit AlatDitambahkan(daftarAlat.length - 1, nama);
    }

    function ubahAlat(
        uint256 id,
        string memory nama,
        uint256 totalStok,
        bool aktif
    ) public onlyAdmin {
        require(id < daftarAlat.length, "Alat tidak ditemukan");
        require(totalStok >= daftarAlat[id].sedangDipinjam,
            "Stok kurang dari jumlah dipinjam");

        daftarAlat[id].nama = nama;
        daftarAlat[id].totalStok = totalStok;
        daftarAlat[id].aktif = aktif;
    }

    function jumlahAlat() public view returns (uint256) {
        return daftarAlat.length;
    }

    function ambilAlat(uint256 id)
        public
        view
        returns (string memory, uint256, uint256, bool)
    {
        require(id < daftarAlat.length, "Alat tidak ditemukan");

        Alat memory a = daftarAlat[id];

        return (
            a.nama,
            a.totalStok,
            a.sedangDipinjam,
            a.aktif
        );
    }

    function ajukanPeminjaman(
        uint256 alatId,
        uint256 jumlah
    ) public {
        require(alatId < daftarAlat.length, "Alat tidak ditemukan");
        require(jumlah > 0, "Jumlah tidak valid");
        require(daftarAlat[alatId].aktif, "Alat tidak aktif");

        daftarPeminjaman.push(
            Peminjaman({
                alatId: alatId,
                jumlah: jumlah,
                peminjam: msg.sender,
                waktuPengajuan: block.timestamp,
                waktuPersetujuan: 0,
                waktuPengajuanKembali: 0,
                waktuPengembalian: 0,
                status: Status.MenungguPersetujuan
            })
        );

        emit PeminjamanDiajukan(
            daftarPeminjaman.length - 1,
            alatId,
            msg.sender
        );
    }

    function setujuiPeminjaman(uint256 id) public onlyAdmin {
        require(id < daftarPeminjaman.length, "Data tidak ditemukan");

        Peminjaman storage p = daftarPeminjaman[id];

        require(
            p.status == Status.MenungguPersetujuan,
            "Status tidak valid"
        );

        Alat storage a = daftarAlat[p.alatId];

        require(a.aktif, "Alat tidak aktif");
        require(
            a.totalStok - a.sedangDipinjam >= p.jumlah,
            "Stok tidak mencukupi"
        );

        a.sedangDipinjam += p.jumlah;

        p.status = Status.Disetujui;
        p.waktuPersetujuan = block.timestamp;

        emit PeminjamanDisetujui(id);
    }

    function tolakPeminjaman(uint256 id) public onlyAdmin {
        require(id < daftarPeminjaman.length, "Data tidak ditemukan");

        Peminjaman storage p = daftarPeminjaman[id];

        require(
            p.status == Status.MenungguPersetujuan,
            "Status tidak valid"
        );

        p.status = Status.Ditolak;

        emit PeminjamanDitolak(id);
    }

    function ajukanPengembalian(uint256 id) public {
        require(id < daftarPeminjaman.length, "Data tidak ditemukan");

        Peminjaman storage p = daftarPeminjaman[id];

        require(p.peminjam == msg.sender, "Bukan peminjam");
        require(p.status == Status.Disetujui, "Status tidak valid");

        p.status = Status.MenungguPengembalian;
        p.waktuPengajuanKembali = block.timestamp;

        emit PengembalianDiajukan(id);
    }

    function konfirmasiPengembalian(uint256 id) public onlyAdmin {
        require(id < daftarPeminjaman.length, "Data tidak ditemukan");

        Peminjaman storage p = daftarPeminjaman[id];

        require(
            p.status == Status.MenungguPengembalian,
            "Status tidak valid"
        );

        daftarAlat[p.alatId].sedangDipinjam -= p.jumlah;

        p.status = Status.Dikembalikan;
        p.waktuPengembalian = block.timestamp;

        emit PengembalianDikonfirmasi(id);
    }

    function jumlahPeminjaman() public view returns (uint256) {
        return daftarPeminjaman.length;
    }

    function ambilPeminjaman(uint256 id)
        public
        view
        returns (
            uint256 alatId,
            uint256 jumlah,
            address peminjam,
            uint256 waktuPengajuan,
            uint256 waktuPersetujuan,
            uint256 waktuPengajuanKembali,
            uint256 waktuPengembalian,
            Status status
        )
    {
        require(id < daftarPeminjaman.length, "Data tidak ditemukan");

        Peminjaman memory p = daftarPeminjaman[id];

        return (
            p.alatId,
            p.jumlah,
            p.peminjam,
            p.waktuPengajuan,
            p.waktuPersetujuan,
            p.waktuPengajuanKembali,
            p.waktuPengembalian,
            p.status
        );
    }
}
