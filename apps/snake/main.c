// vim: set ts=4 sw=4 et:
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "sfos.h"
#include "vdp.h"

#define MAX_X  32
#define MAX_Y  24

#define GAME_SPEED 8

char tb[64];
size_t i;
uint8_t key;

typedef struct SnakeSegment {
    uint8_t x;
    uint8_t y;
    struct SnakeSegment *next;
} SnakeSegment;

typedef enum Direction {
    UP,
    DOWN,
    LEFT,
    RIGHT
} Direction;

SnakeSegment* create_segment(uint8_t x, uint8_t y) {
    SnakeSegment *new_segment = (SnakeSegment *)malloc(sizeof(SnakeSegment));
    if (new_segment == NULL) {
        perror("Failed to allocate memory for snake segment");
        exit(EXIT_FAILURE);
    }
    new_segment->x = x;
    new_segment->y = y;
    new_segment->next = NULL;
    return new_segment;
}
// Function to add a new head to the snake (for movement)
void add_new_head(SnakeSegment **head, uint8_t new_x, uint8_t new_y) {
    SnakeSegment *new_head = create_segment(new_x, new_y);
    new_head->next = *head;
    *head = new_head;
}

// Function to remove the tail of the snake (for movement)
void remove_tail(SnakeSegment **head) {
    SnakeSegment *current = *head;
    SnakeSegment *prev = NULL;

    if (*head == NULL || (*head)->next == NULL) {
        // If the snake has 0 or 1 segments, this function shouldn't be called
        // for normal movement (only when growing)
        return;
    }

    while (current->next != NULL) {
        prev = current;
        current = current->next;
    }

    if (prev != NULL) {
        prev->next = NULL;
    } else {
        // This case should ideally not happen if the snake has >1 segment
        // and we are always guaranteed a previous segment for removing the tail.
        // It would mean the head was the only segment, which is handled by the initial check.
    }
    free(current); // Free the memory of the removed tail segment
}

// Helper to check if a given coordinate (x,y) is on the snake,
// excluding the tail if `exclude_tail` is true.
// This is crucial for the self-collision logic.
uint8_t is_on_snake(SnakeSegment *head, uint8_t check_x, uint8_t check_y, uint8_t exclude_tail) {
    SnakeSegment *current;
    SnakeSegment *tail;
    if (head == NULL) {
        return 0;
    }

    current = head;
    tail = NULL;

    if (exclude_tail) {
        // Find the tail
        while (current != NULL && current->next != NULL) {
            current = current->next;
        }
        tail = current; // tail now points to the last segment
        current = head; // Reset current to head for checking
    } else {
        current = head;
    }

    // Iterate through the snake segments (excluding tail if specified)
    while (current != NULL) {
        if (exclude_tail && current == tail) {
            // Skip the tail segment if we're excluding it
            current = current->next; // Should be NULL if tail is the last
            continue;
        }

        if (check_x == current->x && check_y == current->y) {
            return 1; // Collision detected
        }
        current = current->next;
    }
    return 0; // No collision
}


// Function to generate random food position
void generate_food(uint8_t *food_x, uint8_t *food_y, SnakeSegment *snake_head) {
    uint8_t valid_pos = 0;
    SnakeSegment *current;
    while (!valid_pos) {
        *food_x = rand() % MAX_X;
        *food_y = rand() % MAX_Y;

        // Ensure food doesn't spawn on the snake
        current = snake_head;
        valid_pos = 1; // Assume valid until a collision is found
        while (current != NULL) {
            if (*food_x == current->x && *food_y == current->y) {
                valid_pos = 0; // Food spawned on snake, try again
                break;
            }
            current = current->next;
        }
    }
}

// Function to free all snake segments
void free_snake(SnakeSegment *head) {
    SnakeSegment *current = head;
    SnakeSegment *next_segment;
    while (current != NULL) {
        next_segment = current->next;
        free(current);
        current = next_segment;
    }
}


void draw_snake(struct SnakeSegment *seg)
{
    screen_buf[xy2scr(seg->x, seg->y)] = 0x6;
    if (seg->next != NULL)
        draw_snake(seg->next);

}

void draw_food(uint8_t x, uint8_t y)
{
    screen_buf[xy2scr(x, y)] = 0xf;
}

void print_at_xy(uint8_t x, uint8_t y, char * s) {
        i = (y * 32) + x;
        do {
                screen_buf[i] = *s;
                ++s;
                ++i;
        } while (*s != 0);
}


uint16_t menu(void)
{
    uint16_t seed;
    sfos_c_printstr("\nPress SPACE to start\n");
    do {
        seed++;
    } while (sfos_c_status() != ' ');
    return seed;
}

void get_user_input(void)
{
    uint8_t c = sfos_c_status();
    if (c != 0)
        key = c;
}

void main()
{
    SnakeSegment *snake_head;

    Direction current_direction;
    Direction new_direction;

    uint8_t food_x, food_y;
    int8_t new_head_x, new_head_y;
    uint8_t game_over = 0;
    int score = 0;
    uint8_t ticks = 1;

    vdp_init_g2();
    vdp_set_write_address(VDP_COLOR_TABLE);
    for (i=0; i<(32*24); i++)
    {
        VRAM=0x51;
    }
    srand(menu());

    // Initial snake setup
    snake_head = create_segment(MAX_X / 2, MAX_Y / 2);
    add_new_head(&snake_head, MAX_X / 2, (MAX_Y / 2) + 1); // Add a second segment for a visible body
    current_direction = UP; // Initial direction

    // Food position
    generate_food(&food_x, &food_y, snake_head);

    new_head_x = snake_head->x;
    new_head_y = snake_head->y;
    // Game loop
    while (!game_over) {
        uint8_t k = 0;
        uint8_t will_eat_food;

        get_user_input();
        if (ticks % GAME_SPEED == 0) {
            ticks = 1;
            memset(screen_buf, 0, 0x300);   //clear screen
            draw_food(food_x, food_y);
            draw_snake(snake_head);

            // user input.
            switch (key) {
                case 'a': new_direction = LEFT; break;
                case 's': new_direction = DOWN; break;
                case 'd': new_direction = RIGHT; break;
                case 'w': new_direction = UP; break;
                case 0x1b: game_over = 1;
            }
            if (
                (new_direction == UP && current_direction != DOWN) ||
                (new_direction == DOWN && current_direction != UP) ||
                (new_direction == LEFT && current_direction != RIGHT) ||
                (new_direction == RIGHT && current_direction != LEFT)
            ) {
                current_direction = new_direction;
            }

            switch(current_direction) {
                case UP:    new_head_y = new_head_y - 1; break;
                case DOWN:  new_head_y = new_head_y + 1; break;
                case LEFT:  new_head_x = new_head_x - 1; break;
                case RIGHT: new_head_x = new_head_x + 1; break;
            }

            if (new_head_x < 0 || new_head_x >= MAX_X ||
                new_head_y < 0 || new_head_y >= MAX_Y
            ) {
                game_over = 1;
            }

            if (!game_over)
            {
                will_eat_food = (new_head_x==food_x && new_head_y == food_y);
                if (is_on_snake(snake_head, new_head_x, new_head_y, !will_eat_food))
                    game_over = 1;
                add_new_head(&snake_head, new_head_x, new_head_y);

                if (snake_head->x == food_x && snake_head->y == food_y) {
                    score += 10;
                    generate_food(&food_x, &food_y, snake_head);
                    // Snake grows: do not remove tail
                } else {
                    remove_tail(&snake_head);
                }
            }
            vdp_wait();
            vdp_flush();
        } else {
            vdp_wait();
            ticks++;
        }
    }
    sprintf(tb, "Game Over! Your score was: %d\n", score);
    sfos_c_printstr(tb);
    free_snake(snake_head);
}
