input_parser = import_module("./src/package_io/input_parser.star")
ethereum_package = import_module("github.com/kurtosis-tech/ethereum-package/main.star")
contract_deployer = import_module("./src/contracts/contract_deployer.star")
static_files = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/static_files/static_files.star"
)
participant_network = import_module("./src/participant_network.star")


def run(plan, args={}):
    """Deploy a Optimism L2 with a local L1.

    Args:
        args(yaml): Configures other aspects of the environment.
    Returns:
        A full deployment of Optimism L2
    """

    # Parse the values for the args
    plan.print("Parsing the L1 input args")

    ethereum_args = args["ethereum_package"]

    # Deploy the L1
    plan.print("Deploying a local L1")
    l1 = ethereum_package.run(plan, ethereum_args)
    all_l1_participants = l1.all_participants
    priv_key = l1.pre_funded_accounts[
        12
    ].private_key  # reserved for L2 contract deployer
    # Deploy L2 smart contracts
    plan.print("Deploying the L2 smart contracts")
    first_l1_el_node = all_l1_participants[0].el_context.rpc_http_url
    first_l1_cl_node = all_l1_participants[0].cl_context.beacon_http_url
    el_cl_data = contract_deployer.launch_contract_deployer(
        plan, first_l1_el_node, first_l1_cl_node, priv_key
    )

    # Parse the values for the args
    plan.print("Parsing the L2 input args")
    optimism_args = args["optimism_package"]

    # Deploy the L2
    plan.print("Deploying a local L2")
    args_with_right_defaults = input_parser.input_parser(plan, optimism_args)

    jwt_file = plan.upload_files(
        src=static_files.JWT_PATH_FILEPATH,
        name="op_jwt_file",
    )
    network_params = args_with_right_defaults.network_params

    all_participants = participant_network.launch_participant_network(
        plan,
        args_with_right_defaults.participants,
        jwt_file,
        network_params,
        el_cl_data,
    )

    plan.print(all_participants)
