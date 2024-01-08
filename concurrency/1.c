#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>

#define ANSI_COLOR_RESET "\x1b[0m"
#define ANSI_COLOR_WHITE "\x1b[37m"
#define ANSI_COLOR_YELLOW "\x1b[33m"
#define ANSI_COLOR_CYAN "\x1b[36m"
#define ANSI_COLOR_BLUE "\x1b[34m"
#define ANSI_COLOR_GREEN "\x1b[32m"
#define ANSI_COLOR_RED "\x1b[31m"
// Define coffee types and their preparation times
typedef struct {
    char name[20];
    int preparation_time;
} CoffeeType;

// Define customer information
typedef struct {
    int id;
    char coffee[20];
    int arrival_time;
    int tolerance;
    int barista_index; // Index of the barista serving the customer
    int served; // Flag to track whether the customer has been served
    int left;
    int coffee_preparation_start_time;
    int wait_time;
    int coffe_prep;
} Customer;

// Define barista information
typedef struct {
    int id;
    int served_customers; // Count of served customers
} Barista;

// Define mutex locks and semaphores
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
//sem_t baristas_sem;
sem_t time_sem;
sem_t customer_sem;

// Global variables
time_t start_time;
time_t current_time;
int simulation=0;
int num_baristas;
int num_coffee_types;
int num_customers;
int coffee_wasted=0;
int max_customer=8000;
CoffeeType coffee_types[400];
Customer customers[1000];
int global_time = -1;  // Global clock to track time
Barista baristas[4000];
int all_customers_served_and_left() {
    for (int i = 0; i < num_customers; i++) {
        if (customers[i].served == 0 || customers[i].left == 0) {
            //printf("%d\n",i+1);
            return 0; // There is at least one customer who hasn't left or been served
        }
    }
    return 1; // All customers have left or been served
}
void find_max_customer() {
    int max = customers[0].arrival_time + customers[0].tolerance;
    for (int i = 0; i < num_customers; i++) {
        int current = customers[i].arrival_time + customers[i].tolerance;
        //printf("%d\n",current);
        if (current > max) {
            max = current;
        }
    }
    max_customer = max;
}
// Timer thread to update global_time
void* timer_thread(void* arg) {
    while (1) {
        //printf("4\n");
        sem_wait(&time_sem);
        time(&current_time);
        global_time = difftime(current_time, start_time);
        if (all_customers_served_and_left()||global_time>=max_customer) {
            simulation=1;
            pthread_mutex_unlock(&mutex);
            sem_post(&time_sem);
            sem_post(&customer_sem);
            break;
        }
        time(&current_time);
        global_time = difftime(current_time, start_time);
        for (int i = 0; i < num_customers; i++) {
            if (customers[i].arrival_time <= global_time && !customers[i].served) {
                customers[i].wait_time=global_time-customers[i].arrival_time;
            }
        }
        sem_post(&time_sem);
        sleep(1); // Sleep for 1 second
}
}

// Function to simulate customer arrival and order placement
void* customer_arrival(void* arg) {
    Customer* customer = (Customer*)arg;
    // Wait for the global_time to catch up to the customer's arrival time
    while (1) {
        //printf("3\n");
        if(simulation || global_time>=max_customer){
            pthread_mutex_unlock(&mutex);
            sem_post(&customer_sem);
            break;
        }
        if (customer->arrival_time > global_time) {
            //sched_yield(); // Allow other threads to run
        } else {
            // Customer can proceed
            printf(ANSI_COLOR_WHITE "Customer %d arrives at %d second(s)\n" ANSI_COLOR_RESET, customer->id, global_time);
            printf(ANSI_COLOR_YELLOW "Customer %d orders an %s\n" ANSI_COLOR_RESET, customer->id, customer->coffee);
            sem_post(&customer_sem);
            break;
        }
    }
    // Calculate the time when the customer will leave
    int leave_time = customer->arrival_time + customer->tolerance + 1;
    // Wait until the time the customer will leave
    while (1) {
        if(simulation || global_time>=max_customer){
            pthread_mutex_unlock(&mutex);
            sem_post(&time_sem);
            sem_post(&customer_sem);
            break;
        }
        //printf("%d simu\n",simulation);
        //printf("hai\n");
        if (global_time >= leave_time && customer->left == 0 && customer->coffee_preparation_start_time+customer->coffe_prep+1<leave_time) {
            printf(ANSI_COLOR_RED "Customer %d leaves due to tolerance without their order at %d second(s)\n" ANSI_COLOR_RESET, customer->id, global_time);
            customer->left = 1;
            customer->served = 1;
            pthread_exit(NULL);
        }
        //printf("hello\n");
    }
}

// Function to simulate barista work
void* barista_work(void* arg) {
    Barista* barista = (Barista*)arg;
    while (1) {
        //printf("1\n");
        // Wait for a customer to place an order
        //sem_wait(&baristas_sem);
        if (all_customers_served_and_left() || global_time>=max_customer) {
            //sem_post(&baristas_sem);
            pthread_mutex_unlock(&mutex);
            sem_post(&time_sem);
            sem_post(&customer_sem);
            break;
        }
        sem_wait(&customer_sem);
        pthread_mutex_lock(&mutex);
        // Find a customer whose order can be prepared by this barista
        int customer_index = -1;
        for (int i = 0; i < num_customers; i++) {
            Customer* customer = &customers[i];
            if (customer->tolerance > 0 && !customer->served && global_time>=customer->arrival_time) {
                if (customer->barista_index == -1) {
                    for (int j = 0; j < num_coffee_types; j++) {
                        if (strcmp(customer->coffee, coffee_types[j].name) == 0 &&
                            customer->tolerance >= coffee_types[j].preparation_time) {
                            customer_index = i;
                            customer->barista_index = barista->id;
                            break;
                        }
                    }
                }
            }
            if (customer_index != -1) {
                break;
            }
        }
        pthread_mutex_unlock(&mutex);
        if (customer_index != -1) {
            // Serve the customer
            Customer* customer = &customers[customer_index];
            int preparation_time = 0;
            for (int j = 0; j < num_coffee_types; j++) {
                if (strcmp(customer->coffee, coffee_types[j].name) == 0) {
                    preparation_time = coffee_types[j].preparation_time;
                    break;
                }
            }
            sleep(1);
            sem_wait(&time_sem);
            time(&current_time);
            global_time = difftime(current_time, start_time);
            sem_post(&time_sem);
            printf(ANSI_COLOR_CYAN "Barista %d begins preparing the order of customer %d at %d second(s)\n" ANSI_COLOR_RESET, barista->id, customer->id, global_time);
            customer->coffee_preparation_start_time = global_time;
            customer->coffe_prep=preparation_time;
            // Sleep only for preparation time for the second and subsequent customers
            sleep(preparation_time);
            sem_wait(&time_sem);
            time(&current_time);
            global_time = difftime(current_time, start_time);
            sem_post(&time_sem);
            printf( ANSI_COLOR_BLUE "Barista %d completes the order of customer %d at %d second(s)\n" ANSI_COLOR_RESET, barista->id, customer->id, global_time);
            //(customer->tolerance >= global_time - customer->arrival_time) && 
            if ( customer->left == 0) {
                printf( ANSI_COLOR_GREEN "Customer %d leaves with their order at %d second(s)\n" ANSI_COLOR_RESET, customer->id, global_time);
                customer->left = 1;
                // Mark the customer as served
                customer->wait_time-=preparation_time;
                customer->served = 1;
            }
            else{
                coffee_wasted+=1;
            }
            // Update the served customers count for the barista
            barista->served_customers++;
        } 
    }
}

int main() {
    // Read input
    scanf("%d %d %d", &num_baristas, &num_coffee_types, &num_customers);
    for (int i = 0; i < num_coffee_types; i++) {
        scanf("%s %d", coffee_types[i].name, &coffee_types[i].preparation_time);
    }
    for (int i = 0; i < num_customers; i++) {
        customers[i].id = i + 1;
        customers[i].barista_index = -1;
        customers[i].served = 0;
        customers[i].left = 0;
        customers[i].coffee_preparation_start_time = 0;
        customers[i].wait_time = 0;
        customers[i].coffe_prep=0;
        scanf("%d %s %d %d", &customers[i].arrival_time, customers[i].coffee, &customers[i].arrival_time, &customers[i].tolerance);
    }
    // Initialize semaphores
    //sem_init(&baristas_sem, 0, num_baristas);
    sem_init(&time_sem, 0, 1);
    sem_init(&customer_sem, 0, 0);

    // Initialize baristas
    for (int i = 0; i < num_baristas; i++) {
        baristas[i].id = i + 1;
        baristas[i].served_customers = 0;
    }

    // Create timer thread
    pthread_t timer;
    pthread_create(&timer, NULL, timer_thread, NULL);
    time(&start_time);
    // Create customer threads
    pthread_t customer_threads[num_customers];
    for (int i = 0; i < num_customers; i++) {
        pthread_create(&customer_threads[i], NULL, customer_arrival, &customers[i]);
    }
    // Create barista threads
    pthread_t barista_threads[num_baristas];
    for (int i = 0; i < num_baristas; i++) {
        pthread_create(&barista_threads[i], NULL, barista_work, &baristas[i]);
    }
    // Join customer threads
    for (int i = 0; i < num_customers; i++) {
        pthread_join(customer_threads[i], NULL);
    }
    // Join barista threads
    for (int i = 0; i < num_baristas; i++) {
        pthread_join(barista_threads[i], NULL);
    }
    int total_waiting_time = 0;
    for (int i = 0; i < num_customers; i++) {
        total_waiting_time += customers[i].wait_time;
    }
    double average_waiting_time = (double)total_waiting_time / num_customers;
    printf("Average Waiting Time for Customers: %.2f seconds\n", average_waiting_time);
    printf("Number of coffee wasted: %d\n", coffee_wasted);
    // Clean up
    //sem_destroy(&baristas_sem);
    sem_destroy(&time_sem);
    sem_destroy(&customer_sem);
    pthread_mutex_destroy(&mutex);
    return 0;
}
