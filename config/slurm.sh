res_per_user() {
printf "%-15s %10s %15s %15s\n" "USER" "ALLOC_CPUS" "ALLOC_MEM(GB)" "ALLOC_GPUS"

squeue -h -O "UserName,tres-alloc:200" | awk '
{
    # Get memory value and unit

    # Split the TRES allocation string (format like "cpu=28,mem=128G,node=1...")
    split($2, tres, ",");
    
    # Initialize CPU and memory variables
    cpus = 0;
    mem = "";
    gpus = 0;
    
    # Process each TRES component
    for (i in tres) {
        # Extract CPU allocation
        if (match(tres[i], /cpu=([0-9]+)/)) {
            cpus = substr(tres[i], RSTART+4, RLENGTH-4);
        }
        # Extract memory allocation
        else if (match(tres[i], /mem=([0-9]+[KMGT]?)/)) {
            mem = substr(tres[i], RSTART+4);
        }
        else if (match(tres[i], /gres\/gpu=([0-9]+)/)) {
            gpus = substr(tres[i], RSTART+9, RLENGTH-9);
            # Assume 4 CPUs and 16G memory per GPU if GPUs are allocated
        }
    }
    
    if (cpus == 0) cpus = 1;  # Default to 1 CPU
    if (mem == "") mem = "0";  # Default to 0 memory

    # Sum CPUs and Memory per user
    user_cpus[$1] += cpus;
    user_mem[$1] += mem;
    user_gpus[$1] += gpus;
}
END {
    for (user in user_cpus) {
        printf "%-15s %10d %15.2f %15d\n", user, user_cpus[user], user_mem[user], user_gpus[user];
    }
}' | sort
}
