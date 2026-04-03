#!/usr/bin/env python3
# pyre-unsafe
# Copyright (c) Meta Platforms, Inc. and affiliates.

import os
import unittest

import torch
import torchcomms


class MemPoolTorchCommCCAHookTest(unittest.TestCase):
    def setUp(self) -> None:
        if "TEST_BACKEND" not in os.environ:
            raise AssertionError("TEST_BACKEND not set")
        self.device_ = torch.device("cuda")
        self.backend_ = os.environ["TEST_BACKEND"]
        self.tensor_size_ = 1024 * 1024

        # Initialize CCA hook WITHOUT creating a communicator
        torchcomms.attach_memory_hook(self.backend_)
        self.allocator_ = torchcomms.get_mem_allocator(self.backend_)

    @unittest.skipIf(
        os.getenv("TEST_BACKEND") != "ncclx"
        or torch.cuda.get_device_capability() < (9, 0),
        "Skipping NCCLX-only CCA hook mem pool tests",
    )
    def test_mem_pool_cca_hook_registers_tensor(self) -> None:
        """Verify that a tensor allocated from cuda.MemPool is automatically
        registered with globalRegisterWithPtr via the CCA hook, by constructing
        RdmaMemory with cache_reg=True (which throws if not registered)."""
        pool = torch.cuda.MemPool(self.allocator_)
        with torch.cuda.use_mem_pool(pool):
            tensor = torch.ones(self.tensor_size_, device=self.device_)

        # RdmaMemory(cache_reg=True) looks up the buffer in ctran's RegCache.
        # If the CCA hook registered the segment, this succeeds.
        # If not registered, it raises RuntimeError.
        from torchcomms._transport import RdmaMemory

        rdma_mem = RdmaMemory(tensor, cache_reg=True)
        self.assertIsNotNone(rdma_mem)


if __name__ == "__main__":
    unittest.main()
