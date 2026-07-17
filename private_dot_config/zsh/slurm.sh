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

slurm_gpus() {
    # Define the table header
    # NODE (15) STATE (10) CPUS (12) RAM_ALLOC (10) RAM_AVAIL (10) GPUs (12)
    printf "%-15s %-10s %-12s %-12s %-12s %-15s\n" "NODE" "STATE" "CPUS(A/I)" "MEM_USED" "MEM_FREE" "GPUs(U/T)"
    printf "%.s-" {1..85}; echo ""

    sinfo -N -o "%n %t %C %m %G" --noheader | while read -r node state cpus mem_total_mb gres; do

        # 1. Fetch detailed node info for Allocated Memory and Allocated GPUs
        local node_info=$(scontrol show node "$node")

        # 2. Extract Allocated Memory (AllocMem is in MB)
        local mem_alloc_mb=$(echo "$node_info" | grep -oP 'AllocMem=\K[0-9]+' || echo "0")
        [[ -z "$mem_alloc_mb" ]] && mem_alloc_mb=0

        # 3. Calculate Available Memory (Total - Allocated)
        local mem_avail_mb=$(( mem_total_mb - mem_alloc_mb ))

        # Convert to GB for readability
        local alloc_gb=$(awk "BEGIN {printf \"%.1fG\", $mem_alloc_mb/1024}")
        local avail_gb=$(awk "BEGIN {printf \"%.1fG\", $mem_avail_mb/1024}")

        # 4. Parse GPU Total from GRES string
        local gpu_total=$(echo "$gres" | grep -oP 'gpu:([^:]+:)?\K[0-9]+' || echo "0")
        [[ -z "$gpu_total" ]] && gpu_total=0

        # 5. Parse GPU Used
        local gpu_used=$(echo "$node_info" | grep -oP 'AllocTRES=.*gres/gpu=\K[0-9]+' || echo "0")
        [[ -z "$gpu_used" ]] && gpu_used=0

        # 6. Format CPUS (showing only Allocated/Idle)
        local cpu_summary=$(echo "$cpus" | cut -d'/' -f1,2)

        # Print the row
        printf "%-15s %-10s %-12s %-12s %-12s %-15s\n" \
            "$node" "$state" "$cpu_summary" "$alloc_gb" "$avail_gb" "$gpu_used/$gpu_total"
    done
}
