// address: 0x104f4
int main(int argc, char *argv[], char *envp[]) {
    __size32 local0; 		// m[o6 - 8]
    int o0; 		// r8

    __isoc99_scanf();
    o0 = add1(local0, 12);
    printf("Sum = %ld\n", o0);
    return 0;
}

// address: 0x105a8
__size32 add1(__size32 param1, __size32 param2) {
    return param1 + param2 + 1;
}

