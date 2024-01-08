#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#define MAX_MACHINES 10
#define MAX_FLAVORS 10
#define MAX_TOPPINGS 10
#define MAX_CUSTOMERS 100

// Data structures to store input
struct Machine {
    int id;
    int tm_start;
    int tm_stop;
};
struct orders {
    int customer_index;
    int machine_index;
    int is_preparing;
};
struct Flavor {
    char name[20];
    int prep_time;
};
struct Topping {
    char name[20];
    int quantity;
};
struct CustomerOrder {
    int customer_id;
    int arrival_time;
    int num_ice_creams;
    struct IceCream {
        char flavor[20];
        char toppings[MAX_TOPPINGS][20];
        int num_toppings;
    } ice_creams[MAX_FLAVORS];
    sem_t order_sem;
    int machine_index[MAX_FLAVORS];
    int prepared_index[MAX_FLAVORS];
    int served;
    int served_machine;
    int checked;
};
int N, K, F, T;
sem_t time_sem;
sem_t customer_sem;
sem_t machine_sem;
sem_t served_sem;
time_t start_time;
time_t current_time;
int global_time = 0;
int simulation=0;
int num_customers_served = 0;
struct CustomerOrder orders[MAX_CUSTOMERS];
struct Machine machines[MAX_MACHINES];
struct Flavor flavors[MAX_FLAVORS];
struct Topping toppings[MAX_TOPPINGS];
int num_customers = 0;
int prev_newline = 0;
sem_t toppings_sem; 
sem_t customer_present_sem;
int find_flavor_index(const char* flavor_name) {
    for (int i = 0; i < F; i++) {
        if (strcmp(flavors[i].name, flavor_name) == 0) {
            return i;
        }
    }
    return -1; // Flavor not found
}
int find_max_tm_stop(struct Machine machines[], int N) {
    int max_tm_stop = machines[0].tm_stop;
    for (int i = 0; i < N; i++) {
        if (machines[i].tm_stop > max_tm_stop) {
            max_tm_stop = machines[i].tm_stop;
        }
    }
    return max_tm_stop;
}
int check_toppings_availability() {
    for (int i = 0; i < T; i++) {
        if (toppings[i].quantity > 0) {
            return 1; // At least one topping is available
        }
    }
    return 0; // All toppings are zero
}
void* timer_thread(void* arg) {
    int max_tm_stop = find_max_tm_stop(machines, N);
    while (1) {
        sem_wait(&time_sem);
        time(&current_time);
        global_time = difftime(current_time, start_time);
        if (global_time == max_tm_stop) {
        // Check if all customers have been served
        ;
        simulation = 1; // All customers served, end simulation
        sem_post(&time_sem);
        break;
    }
    sem_post(&time_sem);
    }
}
void* customer_thread(void* arg) {
    struct CustomerOrder* customer = (struct CustomerOrder*)arg;
    while(1){
        if(simulation){
            break;
        }
        if(customer->arrival_time>global_time){
            //sched_yield();
            ;
        }
        else if(!customer->served){
            sem_wait(&customer_sem);
    // Check if the parlour is at capacity (K customers)
    if (num_customers_served < K) {
        // Check ingredient availability for the order
        sem_wait(&toppings_sem);
        int hasIngredients = 1;
        for (int i = 0; i < customer->num_ice_creams; i++) {
            // Check toppings availability
            for (int j = 0; j < customer->ice_creams[i].num_toppings; j++) {
                char* topping = customer->ice_creams[i].toppings[j];
                //printf("%s ok\n",topping);
                for (int k = 0; k < T; k++) {
                    if (strncmp(toppings[k].name, topping,strlen(toppings[k].name)) == 0) {
                        //printf("%d topping\n",toppings[k].quantity);
                        if(toppings[k].quantity>0){
                        ;
                        }
                        else{
                            hasIngredients = 0;
                        }
                    }
                }
            }
        }
        sem_post(&toppings_sem);
        //printf("%d has\n",hasIngredients);
        if(hasIngredients){
            printf("Customer %d arrived at time %d.\n", customer->customer_id, global_time);
            printf("\033[93mCustomer %d placed an order for %d ice creams.\033[0m\n", customer->customer_id, customer->num_ice_creams);
            for (int i = 0; i < customer->num_ice_creams; i++) {
                        printf("\033[93mIce cream %d: %s\033[0m ", i + 1, customer->ice_creams[i].flavor);
                        for (int j = 0; j < customer->ice_creams[i].num_toppings; j++) {
                            printf("\033[93m%s\033[0m ", customer->ice_creams[i].toppings[j]);
                        }
                    }
            //sem_post(&customer_present_sem);
            sem_wait(&served_sem);
            num_customers_served++;
            customer->served=1;
            sem_post(&served_sem);
        }
        else {

            // Customer left due to insufficient ingredients then add the subtracted ingredients
            printf("Customer %d arrived at time %d.\n", customer->customer_id, global_time);
            printf("\033[31mCustomer %d at %d second(s) leaves with an unfulfilled order.\033[0m\n", customer->customer_id, global_time);
            customer->served_machine=1;
            sem_wait(&served_sem);
            num_customers_served++;
            sem_post(&served_sem);
            sleep(1);
            sem_wait(&time_sem);
            time(&current_time);
            global_time = difftime(current_time, start_time);
            sem_post(&time_sem);
            sem_wait(&served_sem);
            num_customers_served--;
            sem_post(&served_sem);
            sem_post(&customer_sem);
            pthread_exit(NULL);
        }
    } else {
        // Release capacity
        printf("Customer %d arrived at time %d.\n", customer->customer_id, global_time);
        printf("\033[31mCustomer %d left due to capacity full at time %d.\033[0m\n", customer->customer_id, global_time);
        customer->served_machine=1;
        sem_post(&customer_sem);
        pthread_exit(NULL);
    }
    sem_post(&customer_sem);
        }
    }
    return NULL;
}
int checkIngredients(int m , int n)
{
    sem_wait(&toppings_sem);
    int f=1;
            for (int j = 0; j < orders[m].ice_creams[n].num_toppings; j++) {
                const char* topping = orders[m].ice_creams[n].toppings[j];
                for (int k = 0; k < T; k++) {
                    if (strncmp(toppings[k].name, topping,strlen(toppings[k].name)) == 0) {
                        if(toppings[k].quantity>0){
                            ;
                        }
                        else{
                            f=0;
                            break;
                        }
                    }
                }
            }
        if(f==1){
            for (int j = 0; j < orders[m].ice_creams[n].num_toppings; j++) {
                const char* topping = orders[m].ice_creams[n].toppings[j];
                for (int k = 0; k < T; k++) {
                    if (strncmp(toppings[k].name, topping,strlen(toppings[k].name)) == 0) {
                        toppings[k].quantity--;
                    }
                }
            }
        }
        else{
            printf("\033[31mCustomer %d at %d second(s) leaves with an unfulfilled order.\033[0m\n", orders[m].customer_id, global_time);
            orders[m].checked=1;
            orders[m].served_machine=1;
            sem_post(&toppings_sem);
            sem_wait(&served_sem);
            num_customers_served--;
            sem_post(&served_sem);
            //sem_post(&customer_sem);
            //pthread_exit(NULL);
            return 0;
        }
    sem_post(&toppings_sem);
    return 1;
}
pthread_mutex_t machine_mutex[MAX_MACHINES];
void* machine_thread(void* arg) {
    struct Machine* machine = (struct Machine*)arg;
    int machine_id = machine->id;
    int working=0;
    while (1) {
        // Check if the machine's shift is active
        if(simulation){
            break;
        }
        //sem_wait(&customer_present_sem);
        if(machine->tm_stop<=global_time){
            printf("\033[33mMachine %d has stopped working at %d second(s).\033[0m\n", machine_id, global_time);
            pthread_exit(NULL);
            break;
        }
        if(machine->tm_start>global_time){
            //sched_yield();
            ;
        }
        else if (global_time <= machine->tm_stop) {
            pthread_mutex_lock(&machine_mutex[machine_id - 1]);
            if (global_time == machine->tm_start && working==0) {
                printf("\033[33mMachine %d has started working at %d second(s).\033[0m\n", machine_id, global_time);
                working=1;
            }
            //sem_wait(&machine_sem);
            int order_found = -1; // Initialize to an invalid value
            int ice_cream_index = -1;
            for (int i = 0; i < num_customers; i++) {
                // Check if the order is not already being prepared by another machine
                    for (int j = 0; j < orders[i].num_ice_creams; j++) {
                        //
                        if (orders[i].machine_index[j] == -1 && orders[i].served==1) {
                            //printf("%d %d hello\n",i,j);
                            int flavorIndexi = find_flavor_index(orders[i].ice_creams[j].flavor);
                            int prep_timei = flavors[flavorIndexi].prep_time;
                            if (global_time + prep_timei + 1 <= machine->tm_stop && orders[i].checked==0 && checkIngredients(i,j)) {
                            ice_cream_index = j;
                            order_found = i;
                            break;
                        }
                        }
                    }
                if (order_found != -1) {
                    break; // Found an order with an ice cream that can be prepared
                }
            }
            if (order_found != -1 && ice_cream_index != -1) {
                // Start preparing this customer's ice cream
                orders[order_found].machine_index[ice_cream_index] = machine_id;
                // Release the machine semaphore
                if(orders[order_found].arrival_time >= machine->tm_start){
                    sleep(1);
                    sem_wait(&time_sem);
                    time(&current_time);
                    global_time = difftime(current_time, start_time);
                    sem_post(&time_sem);
                }
                // Simulate preparation time for the selected ice cream
                int flavorIndex = find_flavor_index(orders[order_found].ice_creams[ice_cream_index].flavor);
                int prep_time = flavors[flavorIndex].prep_time;
                if( global_time + prep_time+1 <= machine->tm_stop){
                printf("\033[36mMachine %d starts preparing ice cream %d of customer %d at %d second(s).\033[0m\n", machine_id, ice_cream_index + 1, orders[order_found].customer_id, global_time);
                //printf("Machine %d starts preparing ice cream %d of customer %d at %d second(s).\n", );
                // Sleep for the total preparation time
                sleep(prep_time); // Sleep for prep_time+1 seconds
                sem_wait(&time_sem);
                time(&current_time);
                global_time = difftime(current_time, start_time);
                sem_post(&time_sem);
                printf("\033[34mMachine %d completes preparing ice cream %d of customer %d at %d second(s).\033[0m\n", machine_id, ice_cream_index + 1, orders[order_found].customer_id, global_time);
                orders[order_found].prepared_index[ice_cream_index]=1;
                // Check if all ice creams for this customer are prepared
                int all_ice_creams_prepared = 1;
                for (int j = 0; j < orders[order_found].num_ice_creams; j++) {
                    if (orders[order_found].prepared_index[j] == -1) {
                        all_ice_creams_prepared = 0;
                        break;
                    }
                }
                
                if (all_ice_creams_prepared) {
                    // Customer's order is complete
                    printf("\033[32mCustomer %d has collected their order(s) and left at %d second(s).\033[0m\n", orders[order_found].customer_id, global_time);
                    sem_wait(&served_sem);
                    orders[order_found].served_machine=1;
                    num_customers_served--;
                    sem_post(&served_sem);
                }
                pthread_mutex_unlock(&machine_mutex[machine_id - 1]);
                }
                else{
                    sleep(machine->tm_stop-global_time);
                    sem_wait(&time_sem);
                    time(&current_time);
                    global_time = difftime(current_time, start_time);
                    sem_post(&time_sem);
                    pthread_mutex_unlock(&machine_mutex[machine_id - 1]);
                    printf("\033[33mMachine %d has stopped working at %d second(s).\033[0m\n", machine_id, global_time);
                    pthread_exit(NULL);
                    break;
                }
            } else {
                pthread_mutex_unlock(&machine_mutex[machine_id - 1]);
                //sched_yield();
            }
        } 
    }
    return NULL;
}
int main() {
    // Read the first line containing N, K, F, T
    char line[100];
    if (fgets(line, sizeof(line), stdin) == NULL) {
        fprintf(stderr, "Failed to read input.\n");
        return 1;
    }
    if (sscanf(line, "%d %d %d %d", &N, &K, &F, &T) != 4) {
        fprintf(stderr, "Invalid input format.\n");
        return 1;
    }    
    for (int i = 0; i < N; i++) {
        if (fgets(line, sizeof(line), stdin) == NULL) {
            fprintf(stderr, "Failed to read machine input.\n");
            return 1;
        }
        if (sscanf(line, "%d %d", &machines[i].tm_start, &machines[i].tm_stop) != 2) {
            fprintf(stderr, "Invalid machine input.\n");
            return 1;
        }
        machines[i].id=i+1;
    }
    for (int i = 0; i < F; i++) {
        if (fgets(line, sizeof(line), stdin) == NULL) {
            fprintf(stderr, "Failed to read flavor input.\n");
            return 1;
        }
        if (sscanf(line, "%s %d", flavors[i].name, &flavors[i].prep_time) != 2) {
            fprintf(stderr, "Invalid flavor input.\n");
            return 1;
        }
    }
    // Read toppings
    for (int i = 0; i < T; i++) {
        if (fgets(line, sizeof(line), stdin) == NULL) {
            fprintf(stderr, "Failed to read topping input.\n");
            return 1;
        }
        if (sscanf(line, "%s %d", toppings[i].name, &toppings[i].quantity) != 2) {
            fprintf(stderr, "Invalid topping input.\n");
            return 1;
        }
        if(toppings[i].quantity==-1){
            toppings[i].quantity=400;
        }
    }
    int consecutive_newlines = 0;
    while (1) {
        if (fgets(line, sizeof(line), stdin) == NULL) {
            fprintf(stderr, "Failed to read customer order input.\n");
            return 1;
        }
        if (line[0] == '\n') {
            consecutive_newlines++;
            if (consecutive_newlines >= 1) {
            break;  // Two consecutive newline characters indicate the end of input
        }
        }
        else{
            consecutive_newlines = 0;
            sscanf(line, "%d %d %d", &orders[num_customers].customer_id, &orders[num_customers].arrival_time, &orders[num_customers].num_ice_creams);
            orders[num_customers].served=0;
            orders[num_customers].served_machine=0;
        for (int j = 0; j < orders[num_customers].num_ice_creams; j++) {
            orders[num_customers].machine_index[j]=-1;
            orders[num_customers].prepared_index[j]=-1;
            orders[num_customers].checked=0;
            if (fgets(line, sizeof(line), stdin) == NULL) {
                fprintf(stderr, "Failed to read ice cream input.\n");
                return 1;
            }
            char flavor[20];
            if (sscanf(line, "%s", flavor) != 1) {
                fprintf(stderr, "Invalid ice cream flavor input.\n");
                return 1;
            }
            strcpy(orders[num_customers].ice_creams[j].flavor, flavor);
            int num_toppings = 0;
            // Read the rest of the line and split by space
            char *rest_of_line = line + strlen(flavor);
            char *topping = strtok(rest_of_line, " ");
            while (topping != NULL) {
                if (num_toppings < MAX_TOPPINGS) {
                    strcpy(orders[num_customers].ice_creams[j].toppings[num_toppings], topping);
                    // Print each topping on a separate line
                    num_toppings++;
                }
                topping = strtok(NULL, " ");
            }

            orders[num_customers].ice_creams[j].num_toppings = num_toppings;
        }
        }
        num_customers++;
        prev_newline = (line[0] == '\n');
    }
    sem_init(&time_sem, 0, 1);
    sem_init(&customer_sem, 0, 1);
    sem_init(&served_sem,0,1);
    sem_init(&machine_sem, 0, N);
    sem_init(&toppings_sem, 0, 1);
    sem_init(&customer_present_sem, 0, 0);
    time(&start_time);
    pthread_t customer_threads[num_customers];
    for (int i = 0; i < num_customers; i++) {
        pthread_create(&customer_threads[i], NULL, customer_thread, &orders[i]);
    }
    pthread_t machine_threads[N];
    for (int i = 0; i < N; i++) {
        pthread_create(&machine_threads[i], NULL, machine_thread, &machines[i]);
    }
    // Create threads for customers
    pthread_t timer;
    pthread_create(&timer, NULL, timer_thread, NULL);
    for (int i = 0; i < num_customers; i++) {
        pthread_join(customer_threads[i], NULL);
    }
     for (int i = 0; i < N; i++) {
        pthread_join(machine_threads[i], NULL);
    }
    for (int i = 0; i < num_customers; i++) {
            if (orders[i].served_machine == 0) {
                printf("\033[31mCustomer %d was not serviced due to unavailability of machines.\033[0m\n",i+1);
            }
    }
    printf("Parlour Closed\n");
    // Wait for all customer threads to finish
    sem_destroy(&time_sem);
    return 0;
}





