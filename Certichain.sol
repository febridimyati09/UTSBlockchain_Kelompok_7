// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CertiChain
 * @notice Sistem Verifikasi Sertifikat dan Ijazah Digital Berbasis Blockchain
 */
contract CertiChain {

    // ------------------------------------------------------------------------
    // 1. ENUM & STRUCT
    // ------------------------------------------------------------------------

    enum StatusSertifikat {
        Valid,
        Dicabut
    }

    struct DataSertifikat {
        string namaPemilik;
        string programStudi;
        string hashDokumen;
        address mahasiswa; // Tambahan: menyimpan dompet mahasiswa di struct
        uint256 tanggalTerbit;
        StatusSertifikat status;

        // Revisi 7.P1
        string alasanPencabutan;
        uint256 waktuPencabutan;
    }

    // ------------------------------------------------------------------------
    // 2. STATE VARIABLES & MAPPING
    // ------------------------------------------------------------------------

    address public adminKampus;

    // Nomor ijazah => data ijazah
    mapping(string => DataSertifikat) public daftarSertifikat;

    // Revisi 7.2 (private/internal agar getter tidak bentrok)
    mapping(address => string[]) private sertifikatMilik;

    // ------------------------------------------------------------------------
    // 3. EVENTS
    // ------------------------------------------------------------------------

    event SertifikatDiterbitkan(
        string indexed nomorIjazah,
        string namaPemilik,
        string programStudi,
        address indexed mahasiswa
    );

    event SertifikatDicabut(
        string indexed nomorIjazah,
        string alasan,
        uint256 waktu
    );

    // ------------------------------------------------------------------------
    // 4. MODIFIER
    // ------------------------------------------------------------------------

    modifier onlyAdmin() {
        require(
            msg.sender == adminKampus,
            "Error: Hanya Admin Kampus yang memiliki akses!"
        );
        _;
    }

    // ------------------------------------------------------------------------
    // 5. CONSTRUCTOR
    // ------------------------------------------------------------------------

    constructor() {
        adminKampus = msg.sender;
    }

    // ------------------------------------------------------------------------
    // 6. FUNGSI PENERBITAN IJAZAH
    // ------------------------------------------------------------------------

    function terbitkanIjazah(
        string memory _nomorIjazah,
        string memory _namaPemilik,
        string memory _programStudi,
        string memory _hashDokumen,
        address _mahasiswa
    ) external onlyAdmin {

        // Validasi nomor ijazah
        require(
            bytes(_nomorIjazah).length > 0,
            "Error: Nomor Ijazah tidak boleh kosong!"
        );

        // Memastikan nomor ijazah belum digunakan
        require(
            bytes(daftarSertifikat[_nomorIjazah].namaPemilik).length == 0,
            "Error: Nomor Ijazah sudah terdaftar!"
        );

        // Revisi 7.1
        require(
            bytes(_namaPemilik).length > 0,
            "Nama pemilik wajib diisi"
        );

        require(
            bytes(_programStudi).length > 0,
            "Program studi wajib diisi"
        );

        require(
            bytes(_hashDokumen).length > 0,
            "Hash dokumen wajib diisi"
        );

        // Revisi 7.2
        require(
            _mahasiswa != address(0),
            "Error: Alamat mahasiswa tidak boleh kosong!"
        );

        // Menyimpan data ijazah
        daftarSertifikat[_nomorIjazah] = DataSertifikat({
            namaPemilik: _namaPemilik,
            programStudi: _programStudi,
            hashDokumen: _hashDokumen,
            mahasiswa: _mahasiswa,
            tanggalTerbit: block.timestamp,
            status: StatusSertifikat.Valid,
            alasanPencabutan: "",
            waktuPencabutan: 0
        });

        // Menambahkan nomor ijazah ke daftar milik mahasiswa
        sertifikatMilik[_mahasiswa].push(_nomorIjazah);

        emit SertifikatDiterbitkan(
            _nomorIjazah,
            _namaPemilik,
            _programStudi,
            _mahasiswa
        );
    }

    // ------------------------------------------------------------------------
    // 7. FUNGSI PENCABUTAN IJAZAH
    // ------------------------------------------------------------------------

    function cabutIjazah(
        string memory _nomorIjazah,
        string memory _alasan
    ) external onlyAdmin {

        // Memastikan ijazah terdaftar
        require(
            bytes(daftarSertifikat[_nomorIjazah].namaPemilik).length > 0,
            "Error: Nomor Ijazah tidak ditemukan!"
        );

        // Memastikan ijazah masih valid
        require(
            daftarSertifikat[_nomorIjazah].status == StatusSertifikat.Valid,
            "Error: Ijazah sudah dalam status dicabut!"
        );

        // Validasi alasan pencabutan
        require(
            bytes(_alasan).length > 0,
            "Error: Alasan pencabutan wajib diisi!"
        );

        // Mengubah status & mencatat info pencabutan
        daftarSertifikat[_nomorIjazah].status = StatusSertifikat.Dicabut;
        daftarSertifikat[_nomorIjazah].alasanPencabutan = _alasan;
        daftarSertifikat[_nomorIjazah].waktuPencabutan = block.timestamp;

        emit SertifikatDicabut(
            _nomorIjazah,
            _alasan,
            block.timestamp
        );
    }

    // ------------------------------------------------------------------------
    // 8. VERIFIKASI IJAZAH
    // ------------------------------------------------------------------------

    function verifikasiIjazah(
        string memory _nomorIjazah
    )
        external
        view
        returns (
            string memory namaPemilik,
            string memory programStudi,
            string memory hashDokumen,
            address mahasiswa,
            uint256 tanggalTerbit,
            bool isValid,
            string memory alasanPencabutan,
            uint256 waktuPencabutan
        )
    {
        require(
            bytes(daftarSertifikat[_nomorIjazah].namaPemilik).length > 0,
            "Error: Ijazah tidak terdaftar di sistem!"
        );

        DataSertifikat memory cert = daftarSertifikat[_nomorIjazah];
        bool statusValid = (cert.status == StatusSertifikat.Valid);

        return (
            cert.namaPemilik,
            cert.programStudi,
            cert.hashDokumen,
            cert.mahasiswa,
            cert.tanggalTerbit,
            statusValid,
            cert.alasanPencabutan,
            cert.waktuPencabutan
        );
    }

    // ------------------------------------------------------------------------
    // 9. MELIHAT DAFTAR IJAZAH MILIK MAHASISWA
    // ------------------------------------------------------------------------

    function lihatIjazahMahasiswa(
        address _mahasiswa
    )
        external
        view
        returns (string[] memory)
    {
        require(
            _mahasiswa != address(0),
            "Error: Alamat mahasiswa tidak valid!"
        );

        return sertifikatMilik[_mahasiswa];
    }
}