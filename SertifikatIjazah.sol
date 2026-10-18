// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Sistem Verifikasi Sertifikat & Ijazah Digital
 * @notice Kontrak untuk menerbitkan dan memverifikasi keaslian ijazah/sertifikat akademik secara desentral.
 */
contract SertifikatIjazah {
    // ------------------------------------------------------------------------
    // 1. STRUKTUR DATA (Enum & Struct)
    // ------------------------------------------------------------------------
    
    // Status keabsahan sertifikat
    enum StatusSertifikat { Valid, Dicabut }

    // Struct memodelkan data ijazah/sertifikat nyata
    struct DataSertifikat {
        string namaPemilik;
        string programStudi;
        string hashDokumen; // Hash IPFS / SHA-256 dari PDF Ijazah
        uint256 tanggalTerbit;
        StatusSertifikat status;
    }

    // ------------------------------------------------------------------------
    // 2. STATE VARIABLES & MAPPING
    // ------------------------------------------------------------------------
    
    address public adminKampus; // Otoritas penerbit (Universitas)
    
    // Mapping: Nomor Ijazah (ID) => Struct DataSertifikat
    mapping(string => DataSertifikat) public daftarSertifikat;

    // ------------------------------------------------------------------------
    // 3. EVENTS (Efisiensi Gas & Logging)
    // ------------------------------------------------------------------------
    
    event SertifikatDiterbitkan(string indexed nomorIjazah, string namaPemilik, string programStudi);
    event SertifikatDicabut(string indexed nomorIjazah, string alasan);

    // ------------------------------------------------------------------------
    // 4. MODIFIER & ERROR HANDLING
    // ------------------------------------------------------------------------
    
    modifier onlyAdmin() {
        require(msg.sender == adminKampus, "Error: Hanya Admin Kampus yang memiliki akses!");
        _;
    }

    constructor() {
        adminKampus = msg.sender;
    }

    // ------------------------------------------------------------------------
    // 5. FUNGSI INTI
    // ------------------------------------------------------------------------

    /// @notice Menerbitkan Ijazah/Sertifikat Baru (Hanya Admin Kampus)
    function terbitkanIjazah(
        string memory _nomorIjazah,
        string memory _namaPemilik,
        string memory _programStudi,
        string memory _hashDokumen
    ) external onlyAdmin {
        require(
            bytes(daftarSertifikat[_nomorIjazah].namaPemilik).length == 0, 
            "Error: Nomor Ijazah sudah terdaftar!"
        );
        require(bytes(_nomorIjazah).length > 0, "Error: Nomor Ijazah tidak boleh kosong!");

        daftarSertifikat[_nomorIjazah] = DataSertifikat({
            namaPemilik: _namaPemilik,
            programStudi: _programStudi,
            hashDokumen: _hashDokumen,
            tanggalTerbit: block.timestamp,
            status: StatusSertifikat.Valid
        });

        emit SertifikatDiterbitkan(_nomorIjazah, _namaPemilik, _programStudi);
    }

    /// @notice Mencabut keabsahan Ijazah jika terjadi kecurangan (Hanya Admin Kampus)
    function cabutIjazah(string memory _nomorIjazah, string memory _alasan) external onlyAdmin {
        require(
            bytes(daftarSertifikat[_nomorIjazah].namaPemilik).length > 0, 
            "Error: Nomor Ijazah tidak ditemukan!"
        );
        require(
            daftarSertifikat[_nomorIjazah].status == StatusSertifikat.Valid, 
            "Error: Ijazah sudah dalam status dicabut!"
        );

        daftarSertifikat[_nomorIjazah].status = StatusSertifikat.Dicabut;

        emit SertifikatDicabut(_nomorIjazah, _alasan);
    }

    /// @notice Fungsi Publik untuk verifikasi keaslian Ijazah oleh Perusahaan/HRD
    function verifikasiIjazah(string memory _nomorIjazah) external view returns (
        string memory namaPemilik,
        string memory programStudi,
        string memory hashDokumen,
        uint256 tanggalTerbit,
        bool isValid
    ) {
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
            cert.tanggalTerbit,
            statusValid
        );
    }
}