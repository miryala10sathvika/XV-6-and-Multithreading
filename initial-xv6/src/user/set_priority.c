#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"
int main(int argc , char *args[])
{
    if(argc<3){
        printf("Please give complete data\n");
        exit(1);
        return -1;
    }
    int pid=atoi(args[1]);
    int priority=atoi(args[2]);
    if(priority<=100 && priority>=0)
    {
        int old_sp = set_priority(pid, priority);
        if (old_sp == -1) {
            printf("Process with given pid does not exists.\n");
            exit(1);
            return -1;
        }
    }
    else
    {
        printf("Please give priority between 1 and 100\n");
        exit(1);
        return -1;
    }
    exit(0);
}