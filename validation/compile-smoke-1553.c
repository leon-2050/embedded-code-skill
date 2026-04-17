#include <stdint.h>

typedef enum {
    MIL1553_MODE_BC = 0,
    MIL1553_MODE_RT = 1,
    MIL1553_MODE_BM = 2
} mil1553_mode_t;

typedef struct {
    uint8_t  command_word;
    uint16_t status_word;
    uint16_t data_words[32];
} mil1553_msg_t;

int main(void) {
    mil1553_mode_t mode = MIL1553_MODE_RT;
    mil1553_msg_t msg = {0};

    return (mode == MIL1553_MODE_RT) ? (int)msg.status_word : 0;
}
