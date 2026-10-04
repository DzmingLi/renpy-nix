#include <bzlib.h>
#include <lzma.h>
#include <string.h>
#include <zlib.h>

int main(void) {
    const char *input = "renpy-nix immutable toolchain roundtrip";
    unsigned char packed[256], unpacked[256];
    size_t length = strlen(input) + 1;
    uLongf packed_length = sizeof(packed), unpacked_length = sizeof(unpacked);
    if (compress(packed, &packed_length, (const Bytef *)input, length) != Z_OK) return 1;
    if (uncompress(unpacked, &unpacked_length, packed, packed_length) != Z_OK) return 2;
    if (unpacked_length != length || memcmp(input, unpacked, length)) return 3;

    unsigned int bz_packed = sizeof(packed), bz_unpacked = sizeof(unpacked);
    if (BZ2_bzBuffToBuffCompress((char *)packed, &bz_packed, (char *)input, length, 1, 0, 0)) return 4;
    if (BZ2_bzBuffToBuffDecompress((char *)unpacked, &bz_unpacked, (char *)packed, bz_packed, 0, 0)) return 5;
    if (bz_unpacked != length || memcmp(input, unpacked, length)) return 6;

    size_t xz_packed = 0, xz_read = 0, xz_unpacked = 0;
    uint64_t limit = UINT64_MAX;
    if (lzma_easy_buffer_encode(1, LZMA_CHECK_CRC64, NULL, (const uint8_t *)input, length,
                               packed, &xz_packed, sizeof(packed)) != LZMA_OK) return 7;
    if (lzma_stream_buffer_decode(&limit, 0, NULL, packed, &xz_read, xz_packed,
                                 unpacked, &xz_unpacked, sizeof(unpacked)) != LZMA_OK) return 8;
    if (xz_unpacked != length || memcmp(input, unpacked, length)) return 9;
    return 0;
}
