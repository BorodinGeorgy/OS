#include <stdio.h>
#include <unistd.h>


int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        printf("Введите имя выходного файла\n");
        return 1;
    }

    char in[1024];
    char out[1024];
    
    int size = 0;
    FILE* out_file = fopen(argv[1], "wb");


    while ((size = read(0, in, sizeof(in))) > 0)
    {
        int position = 0;
        int zeros_count = 0;
        int is_zeros = 0;

        for (int i = 0; i < size; i++)
        {
	    if (in[i] == 0)
	    {
	        is_zeros = 1;
	        zeros_count++;
	        continue;
	    }

	    if (is_zeros)
	    {
	        fwrite(out, 1, position, out_file);
	        fseek(out_file, zeros_count, 1);
	        zeros_count = 0;
	        is_zeros = 0;
	        position = 0;
	    }

	    out[position] = in[i];
	    position++;
        }
        fwrite(out, 1, position, out_file); 
        if (is_zeros)
        {
	    fseek(out_file, zeros_count, 1);
        }
    
        
    }

    fclose(out_file);
    return 0;
}
