#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main()
{
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  for (n = 0; n < NFORK; n++)
  {
    pid = fork();
    if (pid < 0)
      break;
    if (pid == 0)
    {
      // #ifdef PBS
      // int j = (getpid() - 4) % 3; // ensures independence from the first son's pid when gathering the results in the second part of the program
			// switch(j) {
			// 	case 0:
      //     set_priority(getpid(), 1);
			// 		break;
			// 	case 1:
      //     set_priority(getpid(), 51);
			// 		break;
			// 	case 2:
      //     set_priority(getpid(), 99);
			// 		break;
			// }
      // #endif
      if (n < IO)
      {
        //set_priority(getpid(), 80);
        sleep(200); // IO bound processes
      }
      else
      {
        //set_priority(getpid(), 12);
        for (volatile int i = 0; i < 1000000000; i++)
        {
        } // CPU bound process
      }
      //printf("Process %d with %d finished\n", n,getpid());
      exit(0);
    }
  }
  for (; n > 0; n--)
  {
    if (waitx(0, &wtime, &rtime) >= 0)
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  getps();
  exit(0);
}